# Jenkins Controller Setup

This directory contains all files (except the private SSH key) necessary to run a our desired Jenkins controller.

## Table of Contents

<!--toc:start-->

- [Containerfile](#containerfile)
- [Controller Plugins](#controller-plugins)
- [YAML Configuration](#yaml-configuration)
- [Multibranch Pipeline](#multibranch-pipeline)
<!--toc:end-->

## <a id='containerfile' /> Containerfile

This file is used to create a custom Jenkins controller image.
The only reason to use a custom Containerfile is to use _configuration-as-code_ Jenkins plugin to setup the controller via YAML.

The whole idea of YAML configuration is to turn the controller environment into something that can be easily reproducable.

Instead of configuration-as-code, you can also use:

- A named volume to persist `/var/jenkins_home`,
- Take export the volume after you configure the controller via UI,
- Create a `Containerfile` and import the contents of the volume on top of the base image.

The layers of `Containerfile` is ordered in a way that utilizes the layer caching as much as possible:

- Throughout the development, I found that most of the time I tinkered with the configuration file `config.yml` and SSH keys. Therefore I put them at the bottom.
- The plugin installation `jenkins-plugin-cli` takes a lot of time and does not need to be updated that frequently compared to `config.yml`. Therefore it is located above the config and SSH keys.

All the files in this directory are there because of this `Containerfile`, so let's look at them.

## <a id='controller-plugins' /> Controller Plugins

The Jenkins ecosystem utilizes plugins to extend the base functionality of the tool itself.
This project requires a couple of plugins, and since the main goal is to make the configuration reproducable, there is a need to define the plugins and install them via `Containerfile`.

That is why, there is a file called `plugins.txt` which is used by `jenkins-plugin-cli` to install the required plugins.

Here is a list and a brief explanation of the plugins in `plugins.txt`:

- `configuration-as-code`: Allows us to configure Jenkins via YAML.
- `git`: Enables polling and build triggers via Git.
- `workflow-multibranch`: Scans the branches of a repository and automatically creates Pipeline projects from them, preventing us from manually creating each Pipeline.
- `pipeline-model-definition`: Allows us to write Declarative Pipeline's instead of Scriptive.
- `ssh-slaves`: Allows the Jenkins controller to connect to an agent via SSH, instead of inbound TCP.
- `ssh-agent`: Allows a Jenkins agent to use SSH credentials. It is optional.
- `pipeline-stage-view`: It visualizes the steps of a pipeline in the main page.
- `dark-theme`: Enables dark theme in Jenkins. Optional as well.
- `job-dsl`: Enables us to define `jobs` in the configuration YAML.

## <a id='yaml-configuration' /> YAML Configuration

`config.yml` is the main file that is used to configure Jenkins.
There are comments added for most of the individual option, but generally it consists of 4 main parts:

- System configuration
- System tool configuration
- Pipeline configuration
- Credentials
- Plugin configuration
- Theme

Unfortunately, the documentation around `configuration-as-code` is not that detailed, and it requires you to do a lot of trial and errors.

There are example configurations in [its main repository](https://github.com/jenkinsci/configuration-as-code-plugin), but if you cannot find an example for your needs, there are a couple of things you can do:

- You can configure Jenkins via UI, and then view the configuration under `/manage/configuration-as-code/viewExport` and put this export in version control.
- You can try to find your way through the JSON schema, which is located on `/manage/configuration-as-code/schema`.

Please keep in mind that you can't configure Jenkins by using both `configuration-as-code` and the UI itself.

If you use `configuration-as-code`, anything you do via UI gets overwritten when the instance is restarted.

## <a id='multibranch-pipeline' /> Multibranch Pipeline

The last file we can mention is `local-multibranch.groovy`, which is a Groovy script that is used by `config.yml` to define our Multibranch Pipeline via code.

Unfortunately, in order to define jobs via `configuration-as-code`, we need to utilize `job-dsl` plugin and use a Groovy script.
Jobs are not configurable with YAML.

All this script does is to define a Multibranch Pipeline with the options below:

- By default, Jenkins checks the root of the repository to find the `Jenkinsfile`. In this project, the `Jenkinsfile` is actually under `.pipeline` so the default location is changed.

- Instead of taking Github as the main branch source, it takes the local Git repository. The remote location format `file://<repo-location>` is the format that is used by `git clone`.
  You can check `man git-clone` to see the available Git URLs.

- Finally, it defines a strategy to keep only one build item of a removed branch, and discard the rest.

In order to understand what can be used in this script, you can go to `/plugin/job-dsl/api-viewer/index.html` to see the whole `job-dsl` documentation.
