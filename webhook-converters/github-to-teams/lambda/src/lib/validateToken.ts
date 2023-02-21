import crypto from "crypto";

export default function(a: string, b: string): boolean {
  const aBuffer = Buffer.from(a);
  const bBuffer = Buffer.from(b);

  return crypto.timingSafeEqual(aBuffer, bBuffer);
}
