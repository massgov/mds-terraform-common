.PHONY: all clean prepare

all: clean prepare package/lambda.zip

clean:
	rm -f package/lambda.zip

prepare:
	mkdir -p package

lambda/dist/lambda.js:
	cd lambda && npm run build

package/lambda.zip: lambda/dist/lambda.js
	zip -j package/lambda.zip lambda/dist/lambda.js