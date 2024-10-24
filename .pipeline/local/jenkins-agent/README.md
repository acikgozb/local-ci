# Jenkins Agent Setup

The main bulk of the work happens on the agent, so it is important to understand how it is configured.

The Jenkins agent in this project is configured to satisfy the requirements below:

- It should have Java installed,
- It should have SSH to allow remote connections from controller,
- It should use Podman to run ephemeral containers during the pipeline execution.

The `Containerfile` in this directory serves to fulfill these requirements.

## Table of Contents

<!--toc:start-->

- [Base Image](#base-image)
- [Agent Executable](#agent-executable)
- [SSH](#ssh)

<!--toc:end-->

## <a id='base-image' /> Base Image

For the agent, Podman is used as a base image because the agent needs a container engine to boot up ephemeral containers during the pipeline execution.

Since the agent itself is running in a Podman container, having Podman as a base image turns the agent into what is called Podman-in-Podman (PinP). This is really similar to the term Docker-in-Docker (DinD).

The reason why I'm using Podman is:

- I'm currently using Podman in my main host, and I did not want to mix both technologies because it is advised to go all Podman or Docker.
- In DinD approach, the container starts up multiple processes and additional configuration is needed for the container users to use Docker without elevated privileges. For Podman, all you need to do is to include the base image and that is it. If you check the container, you will see that `podman` does not run a daemon unlike `docker`, which is an additional plus.
- Everything is rootless and least privilege principle is enforced by default, which is quite nice to have even for a PoC.

## <a id='agent-executable' /> Agent Executable

A Jenkins agent is essentially a small `java` executable which is transferred from a Jenkins controller at the beginning of any job.
So, Java 17 is added to the image (the same version used for the controller).

## <a id='ssh' /> SSH

As a last point, `openssh-server` is added to our agent image to spin up a SSH server.

To make things a little bit more interesting, instead of running SSH server as `root`, it is configured to be run as the user `jenkins`, which is the same user that the controller uses to connect.

To achieve this, here is a list of the changes that is done after `openssh-server` installation:

- `.ssh` directory is created for the user `jenkins`,
- The public key of the controller (which is created during the installation) is copied as `authorized_keys` to allow our controller to connect,
- Necessary SSHD host keys are added under `.ssh`,
- A basic SSHD config is added as `sshd_config`, similar to `/etc/ssh/sshd_config`.
- The port 2222 is exposed (since the container is rootless, the well-known default port 22 is not used).

Finally, an entrypoint is defined at the end to run SSHD with the user `jenkins`.
