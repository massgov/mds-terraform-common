.PHONY: build clean prepare check_types lint

build: clean prepare check_types lint lambda/dist/lambda.zip

clean:
	rm -f lambda/dist/lambda.zip

prepare:
	cd lambda && npm i

lambda/dist/lambda.zip:
	cd lambda && npm run build

check_types:
	cd lambda && npm run tsc

lint:
	cd lambda && npm run prettier:check
