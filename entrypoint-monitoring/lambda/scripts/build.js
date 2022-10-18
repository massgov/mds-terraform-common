require('esbuild')
  .build({
    entryPoints: [
      'src/lambda.ts',
    ],
    bundle: true,
    platform: 'node',
    target: 'node12',
    external: [
      '@aws-sdk/*',
    ],
    outfile: 'dist/lambda.js',
  })
  .then(() => {
    console.log('The lambda JS file was created. Please commit it with the source changes!')
  })
  .catch(() => process.exit(1))
