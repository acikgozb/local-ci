.PHONY: unit-tests
unit-tests:
	cd src; go test -v .; cd -;

.PHONY: lint
lint:
	cd src; golangci-lint run -v; cd -;
