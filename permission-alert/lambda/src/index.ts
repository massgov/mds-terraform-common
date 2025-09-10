import { IAMClient, GetPolicyCommand, GetPolicyVersionCommand, ListAttachedRolePoliciesCommand, ListRolePoliciesCommand, GetRolePolicyCommand } from "@aws-sdk/client-iam";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN || "";
const ADMIN_ARN     = "arn:aws:iam::aws:policy/AdministratorAccess";

function loadTargetRoles(): string[] {
  const rawRoles = process.env.TARGET_ROLES?.trim();
  const single   = process.env.TARGET_ROLE?.trim();
  if (rawRoles) {
    try {
      const j = JSON.parse(rawRoles);
      if (Array.isArray(j)) {
        return j.map(x => String(x).trim()).filter(Boolean);
      }
    } catch {

      return rawRoles.split(",").map(x => x.trim()).filter(Boolean);
    }
  }
  return single ? [single] : [];
}

const TARGET_ROLES = Array.from(new Set(loadTargetRoles()));

const iam = new IAMClient({});
const sns = new SNSClient({});

type PolicyDoc = Record<string, any> | null;

function normalize<T>(v: T | T[] | undefined | null): T[] {
  if (v == null) return [];
  return Array.isArray(v) ? v : [v];
}

function tryParsePolicyDoc(raw: any): PolicyDoc {
  if (!raw) return null;
  if (typeof raw === "object") return raw as PolicyDoc;
  if (typeof raw === "string") {
    // Inline policies are sometimes likely url encoded
    const variants = [
      raw,
      raw.replace(/\+/g, " "),
      (() => { try { return decodeURIComponent(raw); } catch { return raw; } })(),
      (() => { try { return decodeURIComponent(raw.replace(/\+/g, " ")); } catch { return raw; } })(),
    ];
    for (const s of variants) {
      try { return JSON.parse(s); } catch { /* oof keep trying */ }
    }
  }
  return null;
}

function hasAdminWildcards(doc: PolicyDoc): boolean {
  if (!doc) return false;
  let stmts: any = (doc as any).Statement ?? [];
  if (!Array.isArray(stmts)) stmts = [stmts];

  for (const s of stmts) {
    if (String(s?.Effect ?? "").toLowerCase() !== "allow") continue;
    const actions   = normalize<string>(s?.Action).map(String);
    const resources = normalize<string>(s?.Resource).map(String);

    const actionWild   = actions.some(a => a.includes("*"));
    const resourceWild = resources.some(r => r === "*" || r.includes("*"));

    if (actionWild && resourceWild) return true;
  }
  return false;
}

async function roleHasAdmin(roleName: string): Promise<{ isAdmin: boolean; reason: string }> {
  // straight AdministratorAccess attachment
  {
    let marker: string | undefined = undefined;
    do {
      const out = await iam.send(new ListAttachedRolePoliciesCommand({ RoleName: roleName, Marker: marker }));
      for (const ap of out.AttachedPolicies ?? []) {
        if (ap.PolicyArn === ADMIN_ARN) {
          return { isAdmin: true, reason: "AdministratorAccess managed policy attached" };
        }
      }
      marker = out.Marker;
    } while (marker);
  }

  // find them wildcards inside managed policies
  {
    let marker: string | undefined = undefined;
    do {
      const out = await iam.send(new ListAttachedRolePoliciesCommand({ RoleName: roleName, Marker: marker }));
      for (const ap of out.AttachedPolicies ?? []) {
        if (!ap.PolicyArn) continue;
        const pol = await iam.send(new GetPolicyCommand({ PolicyArn: ap.PolicyArn }));
        const verId = pol.Policy?.DefaultVersionId;
        if (!verId) continue;

        const ver = await iam.send(new GetPolicyVersionCommand({ PolicyArn: ap.Policy?.Arn!, VersionId: verId }));
        const doc = tryParsePolicyDoc(ver.PolicyVersion?.Document as any);
        if (hasAdminWildcards(doc)) {
          return { isAdmin: true, reason: `Wildcard admin detected in managed policy ${ap.PolicyName}` };
        }
      }
      marker = out.Marker;
    } while (marker);
  }

  // find them Wildcards inside inline policies
  {
    let marker: string | undefined = undefined;
    do {
      const out = await iam.send(new ListRolePoliciesCommand({ RoleName: roleName, Marker: marker }));
      for (const name of out.PolicyNames ?? []) {
        const pol = await iam.send(new GetRolePolicyCommand({ RoleName: roleName, PolicyName: name }));
        const doc = tryParsePolicyDoc(pol.PolicyDocument ?? "");
        if (hasAdminWildcards(doc)) {
          return { isAdmin: true, reason: `Wildcard admin detected in inline policy ${name}` };
        }
      }
      marker = out.Marker;
    } while (marker);
  }

  return { isAdmin: false, reason: "" };
}

async function publish(message: any): Promise<void> {
  await sns.send(new PublishCommand({
    TopicArn: SNS_TOPIC_ARN,
    Subject: "ALERT: Role granted Administrator-like privileges",
    Message: JSON.stringify(message),
  }));
}

function extractEventRoleName(evt: any): string | undefined {
  try {
    const detail = evt?.detail ?? {};
    const req    = detail?.requestParameters ?? {};
    return req?.roleName;
  } catch {
    return undefined;
  }
}

export const handler = async (event: any) => {
  if (!SNS_TOPIC_ARN) {
    return { ok: false, error: "SNS_TOPIC_ARN not set" };
  }
  if (TARGET_ROLES.length === 0) {
    return { ok: true, skipped: true, reason: "no TARGET_ROLES configured" };
  }

  const monitored = TARGET_ROLES;
  const roleInEvent = extractEventRoleName(event);

  let rolesToCheck: string[] = [];
  if (roleInEvent) {
    if (!monitored.includes(roleInEvent)) {
      return { ok: true, skipped: true, reason: `event not for a monitored role (${roleInEvent})` };
    }
    rolesToCheck = [roleInEvent];
  } else {
    rolesToCheck = monitored;
  }

  const findings: Array<{ role: string; alerted: boolean; reason?: string }> = [];
  let alertedAny = false;

  for (const rn of rolesToCheck) {
    const { isAdmin, reason } = await roleHasAdmin(rn);
    if (isAdmin) {
      await publish({
        role: rn,
        reason,
        note: "Detected AdministratorAccess or wildcard Allow (* on Action AND Resource).",
      });
      alertedAny = true;
      findings.push({ role: rn, alerted: true, reason });
    } else {
      findings.push({ role: rn, alerted: false });
    }
  }

  return { ok: true, alerted_any: alertedAny, findings, monitored_roles: monitored, event_role: roleInEvent };
};
