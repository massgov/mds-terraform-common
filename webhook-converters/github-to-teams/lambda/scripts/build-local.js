require('esbuild')
  .build({
    entryPoints: [
      'src/local.ts',
    ],
    bundle: true,
    platform: 'node',
    target: 'node16',
    outfile: 'dist/local.js',
  })
  .catch(() => process.exit(1))
