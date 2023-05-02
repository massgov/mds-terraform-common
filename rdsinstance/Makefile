# Run 'make build'
.PHONY: clean build

build: clean dist/backup_lambda.zip dist/cleanup_lambda.zip

clean:
	rm -f dist/*

dist/backup_lambda.zip:
	pushd src/backup_lambda && npm run build && popd

dist/cleanup_lambda.zip:
	pushd src/cleanup_lambda && npm run build && popd