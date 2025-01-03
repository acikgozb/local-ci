# Local CI with Jenkins

This PoC contains a simple configuration to see what it takes to run Jenkins locally to test a pipeline or the CI checks of a project.

## Table of Contents

<!--toc:start-->

- [Requirements](#requirements)
- [Installation](#installation)
  - [One Command to Install Them All](#one-command-to-install-them-all)
  - [Create an SSH Key/Pair](#create-an-ssh-keypair)
  - [Create Podman Images](#create-podman-images)
  - [Create CI Network](#create-ci-network)
- [Usage](#usage)
  - [Starting the Build Environment](#starting-the-build-environment)
  - [Triggering a Build](#triggering-a-build)
    - [Triggering a Build With Git Commit](#triggering-a-build-with-git-commit)
  - [Cleaning Up](#cleaning-up)
- [More Details](#more-details)
- [Issues](#issues)
- [TODO](#todo)
<!--toc:end-->

## <a id='requirements'/> Requirements

In order to run this PoC locally, you need to install [Podman](https://podman.io/) on your host.

I used Podman because the idea of rootless containers and a native systemd integration sounds a LOT better than what Docker offers at the moment:

- A gigantic daemon,
- Single point of failure,
- Rootful (by default)

Podman really feels like it is **the** perfect transition to Kubernetes.
Also, it was something I did not work with before, so I wanted to try it out.

PS: Podman claims that it is a drop-in replacement of Docker, so you can try to run the project by using a simple alias on your shell environment:

```bash
alias docker=podman
```

Keep in mind that I did not develop with Docker, so I do not guarantee that the above method works seamlessly.

Other than this, if you want to play with the service itself, you need to have [Golang runtime](https://go.dev/dl/) installed on your host as well.

## <a id='installation'/> Installation

The installation is done through `make` targets for you to run as easily as possible.
Do not try to run the targets without looking at here first, because the ordering matters if you wish to change one of the steps for your own preferences.

All of the installation steps should be run at the project root.

### <a id='one-command-to-install-them-all'/> One Command to Install Them All

If you just want to run this project as fast as possible, just run the target below:

```bash
make install
```

This sets up pretty much everything with defaults, so if you use this you can skip to the next section.
If you wish to learn more about what is going on, I would recommend you to keep reading.

### <a id='create-an-ssh-keypair'/> Create an SSH Key/Pair

The very first step of the installation is to create an _ed25519_ SSH key/pair.

The build environment consists of a single Jenkins controller and a permanent Jenkins node (agent).
Each time a build is triggered, the controller is connected to the agent via SSH.
So we need to have this key pair first before moving on.

```bash
make ssh-pair
```

This `make` target places two keys in specific directories:

- `agent-ssh-key.pub`: The public SSH key for our SSH communication, this goes to our agent -> `.pipeline/local/jenkins-agent`.
- `agent-ssh-key`: The private SSH key, this goes to our controller -> `.pipeline/local/jenkins-controller`.

I would recommend you to not change the key names or their locations, otherwise you would need to make changes in other steps as well.

### <a id='create-podman-images'/> Create Podman Images

The next step is creating our Jenkins controller and agent images which we use to create our build environment.

```bash
make images
```

This `make` target does the following:

- It reads the `Containerfile`s under `.pipeline/local/jenkins-agent` and `.pipeline/local/jenkins-controller` and creates Podman images from them.
- It copies necessary configuration files and SSH keys to the images based on the defaults.
- It tags the images as `jenkins-controller` and `jenkins-agent`, so later on you can work with these images manually if you want.

If you decide to change the location or names of your SSH keys, you need to update the script to override the build arguments:

```bash
podman build -t jenkins-controller ./.pipeline/local/jenkins-controller/Containerfile --build-arg PRIVATE_SSH_KEY_PATH=<private-key-location> .
podman build -t jenkins-agent ./.pipeline/local/jenkins-agent/Containerfile --build-arg PUBLIC_SSH_KEY_PATH=<pub-key-location> .
```

### <a id='create-ci-network'/> Create CI Network

Our controller and agent need to be in the same network in order to communicate.
To make things simple, run the target below to create a persistent named network `ci` with a specific subnet `10.89.0.0/29`.

```bash
make net
```

In the project, the controller is set up to run on `10.89.0.2` and the agent is on `10.89.0.3`.
The IP of agent is important since this value is used during SSH, therefore if you decide to change it you can manually create a network and add custom IP's to Jenkins configuration as well.

---

And that's it.
Like I said before, you can just use `make install` to do a one step installation, and later on check the scripts to see what they actually do.

## <a id='usage'/> Usage

The usage is pretty straightforward, like you would expect from a pipeline:

- A change is made on the project,
- That change triggers a builds on the pipeline,
- The pipeline gives a feedback about the change.

Let's see how to get this project up and running.

### <a id='starting-the-build-environment'/> Starting the Build Environment

To start the build environment, run:

```bash
make start
```

Shortly after, you will see 2 containers running successfully (`jenkins-controller` and `jenkins-agent`).

Jenkins UI is served through `127.0.0.1:8080`, so you can login to Jenkins with user and password `admin` and check around.

### <a id='multibranch-pipeline'/> Multibranch Pipeline

When you first login your Jenkins instance and go to `/job/ci-pipeline`, you will see that Jenkins scans the repository to configure a Multibranch pipeline.
The configuration is written in a way that triggers an initial build for each pipeline in a multibranch project.

Seeing a green icon next to the pipeline means that the controller has successfully connected to the agent via SSH and the `Jenkinsfile` has been executed successfully.

From here on, you can check each multibranch pipeline to see their console output or you can go back to the service and make some changes to trigger the build.

### <a id='triggering-a-build'/> Triggering a Build

The next step would be to trigger a build to test our pipeline.
There are 2 ways of doing it in this project, and you can go with the one that you prefer the most:

- You can trigger a build manually after doing a change in the service.
- You can notify Jenkins after a Git event (e.g commit) and Jenkins can start the build with the latest change.

To trigger a build manually, you can go to the pipeline page from Jenkins UI: `/job/ci-pipeline/`.
From there, click on the branch you want to run the build, and then press "Build Now".

You can also trigger a build automatically via _Git commits_, to run the project as frictionless as possible.

#### <a id='triggering-a-build-with-git-commit'/> Triggering a Build With Git Commit

In order to setup a Git commit trigger, we need to have 2 things:

- A `post-commit` Git hook, which is used by Git upon any successful commit.
- An access token to authenticate our local repository to securely notify Jenkins.

So, follow the steps below to setup the trigger.

1 - Login to Jenkins and navigate to `/manage/configureSecurity`.
In that page, there is a section called "Git plugin notifyCommit access tokens".
Create a token from there and put it in `post-commit` script.

2 - Run the make target below:

```bash
make build-trigger
```

This is a simple `cp` script that puts the `post-commit` script under `.git/hooks` to be used by Git itself. Nothing special.

And that's it!
Now whenever you commit a change, you can immediately see a build on the queue under `/job/ci-pipeline/<your-branch-name>`.

### <a id='cleaning-up'/> Cleaning Up

If you want to destroy the entire build environment, you can simply run our last `make` target:

```bash
make rm
```

This will wipe out pretty much everything you've done during the installation except the images.

## <a id='more-details'/> More Details

Here is a list of README's you can check to learn more about each specific part of this PoC:

- [Service](./src/README.md)
- [Controller](./.pipeline/local/jenkins-controller/README.md)
- [Agent](./.pipeline/local/jenkins-agent/README.md)
- [Jenkinsfile](./.pipeline/README.md)

## <a id='issues'/> Issues

If you encounter any issues, I would love to hear them out!
At the end, this PoC is done to provide a playground for people who have something similar in their minds.

So if you can't get use this project or it needs too much manual work to be useful, please open a new issue and let me know.

## <a id='todo'/> TODO

Even though this is a PoC project, it doesn't mean it has to stay simple!
So here is a small list of TODOs that I wish to develop:

- Currently, the `Jenkinsfile` only supports pre-build images.
  However, there might be some cases where a custom `Dockerfile` or `Containerfile` needs to be used as the build container.
- More examples with other common steps (artifact generation, notification, etc.) could be better.

So, to address these concerns, it might be a good idea to have a couple of examples to see what we can do with pipelines on our local hosts.
