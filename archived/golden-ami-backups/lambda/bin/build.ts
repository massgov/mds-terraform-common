import esbuild from "esbuild";
import path from "path";
import os from "os";
import { createWriteStream, promises as fs } from "fs";
import archiver from "archiver";
import { finished } from "stream";
import { promisify } from "util";

const finishedp = promisify(finished);

const run = async (): Promise<void> => {
  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "ssr_ami_backups_"));
  await esbuild.build({
    entryPoints: [path.join(__dirname, "..", "src", "index.ts")],
    bundle: true,
    platform: "node",
    target: "node18",
    outfile: path.join(tmp, "index.js"),
    external: [
      "@aws-sdk/client-ssm",
      "@aws-sdk/client-sns",
      "@aws-sdk/client-ec2",
    ],
  });
  const archivePath = path.join(__dirname, "..", "dist", "lambda.zip");
  const output = createWriteStream(archivePath);
  const archive = archiver("zip", {
    zlib: { level: 9 },
  });

  archive.on("error", (err) => {
    throw err;
  });

  archive.pipe(output);
  archive.directory(tmp, false);
  archive.finalize();

  await finishedp(archive);

  const { size } = await fs.stat(archivePath);
  console.log(`Wrote ${size} bytes to ${archivePath}`);
};

run();
