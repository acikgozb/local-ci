# Jenkinsfile

A `Jenkinsfile` is the pipeline definition that is used by a Jenkins controller.
Each step in the `Jenkinsfile` is executed by either the controller (by default - though not recommended) or a designated agent based on how the build environment is configured.

This README goes into the detail of our `Jenkinsfile`.

## Table of Contents

<!--toc:start-->

- [`agent`](#agent)
- [`options`](#options)
- [`triggers`](#triggers)
- [`environment`](#environment)
- [Clean Workspace](#clean-workspace)
- [Dump Environment Variables](#dump-environment-variables)
- [Checkout](#checkout)
- [Start Build Container](#start-build-container)
- [CI Checks](#ci-checks)
- [Post Actions](#post-actions)
- [Utilities](#utilities)

<!--toc:end-->

## <a id='agent' /> `agent`

The `agent` directive instructs the controller about where the individual step should run. If this directive is used at the beginning of the pipeline, it means that the specified agent will be responsible for executing all of the steps.

The value `default` is used because the agent is configured to run only if there is a matching label expression on the pipeline declaration.

## <a id='options' /> `options`

This directive is used to prevent the default checkout mechanism of Declarative Pipeline.
Since the repository is bind mounted onto the controller and the agent, a Git checkout is not needed.

## <a id='triggers' /> `triggers`

The sole purpose of using a `triggers` directive is to enable version control polling.
Polling needs to be enabled in order to trigger builds via local Git commits.

The `notifyCommit` endpoint of Jenkins Git plugin only works if polling is enabled on the pipeline.

## <a id='environment' /> `environment`

The `environment` directive is used to define variables that are used frequently throughout the build. Here is a brief explanation of them:

- `TIMEOUT`: This variable is used as a command that is given to the ephemeral build container. The value is set to default Jenkins timeout.
- `IMAGE`: This is the image that will be used to spin up a build container.
- `CONTAINER_NAME`: A unique name that represents containers that are associated with each build.
- `EXEC`: This is used as an alias during each step to make it easier to run commands on the build container.

## <a id='clean-workspace' /> Clean Workspace

The very first step of the pipeline is cleaning up the previous build's results.
This contains:

- Previous mock "checkout" of the repository,
- Stopping and removing the ephemeral container.

## <a id='dump-environment-variables' /> Dump Environment Variables

This step is added to visualize the environment variables that exist on the agent on each build.

## <a id='checkout' /> Checkout

This step is not actually a real checkout, instead it takes advantage of the bind mount `/home/enkins/agent/repo`.
Since the changes done on a bind mount is synced both ways, this eliminates the need for cloning the actual repository. A simple copy to the target workspace is enough to simulate a checkout.

---

PS: It is also possible to spin up another container as a Git server and then serve the repository from there (to both controller and agent), but I used bind mounts instead to keep things simple.

Also, I wanted to keep everything in local so that is the reason why Github or any other remote VCS is not used.

---

## <a id='start-build-container' /> Start Build Container

After the checkout step, the pipeline starts the build container to do the checks.
If `${IMAGE}` exists from previous builds, it does not pull the image again.

This step starts the build container with a unique name to allow the developers to troubleshoot a certain issue.

## <a id='ci-checks' /> CI Checks

When the build container is started, the pipeline executes the CI checks which are simple `make` targets (`make lint` and `make unit-tests`).

## <a id='post-actions' /> Post Actions

There are some simple post actions which does different things depending on the state of the pipeline:

- `always`: Regardless of the state of the pipeline, the build containers are stopped.
- `success`: Upon a successful build, the build container is removed entirely.
- `failure`: Upon a failed build, the build container is left untouched thus it can be inspected later on.

## <a id='utilities' /> Utilities

Besides the steps, there is a utility function which is implemented to remove printing the commands on Console Output.

This is done by using toggling the shell mode (`set +x` and `set -x`).
