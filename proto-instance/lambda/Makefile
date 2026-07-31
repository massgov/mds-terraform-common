.PHONY: clean prepare

all: clean prepare .dist/handler/package.zip

clean:
	rm -rdf .dist

prepare:
	npm ci
	mkdir -p .dist/handler

.dist/handler/index.js:
	npx esbuild index.ts \
		--bundle \
		--platform=node \
		--target=node24 \
		--outfile=.dist/handler/index.js \
		"--external:@aws-sdk/*"

.dist/handler/package.zip: .dist/handler/index.js
	cd .dist/handler \
	 && zip package.zip index.js


