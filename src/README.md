# The Example Service

To give the whole context, the example service is written in a way that satisfies the requirements below:

- The service should be testable,
- The service should be checked for linting.

Therefore it is kept as simple as possible to keep the focus on Jenkins.

## Usage

To run the unit tests, you can use:

```bash
make unit-tests
```

To run the linter, you can use:

```bash
make lint
```

Keep in mind that for the lint, you need to have `golangci-lint` installed on your host if you want to run it locally.
If you do not want to install, you can rely on Jenkins to run lints for you as that is the whole point of the project.
