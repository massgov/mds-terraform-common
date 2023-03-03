import esbuild from "esbuild";
import path from "path";
import os from "os";
import { createWriteStream, promises as fs } from "fs";
import archiver from "archiver";
import { finished } from "stream";
import { promisify } from "util";

const finishedp = promisify(finished);

const run = async (): Promise<void> => {
  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "teamsalerts_build_"));
  await esbuild.build({
    entryPoints: [path.join(__dirname, "..", "src", "index.ts")],
    bundle: true,
    platform: "node",
    target: "node12",
    outfile: path.join(tmp, "lambda.js"),
  });
  const archivePath = path.join(__dirname, "..", "dist", "archive.zip");
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
