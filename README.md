# Builderator

Orchestration and configuration of the code development life-cycle.

## Commands

### `local [PROFILE = default]`

Provision a local VM using Vagrant and, by default, VirtualBox. Uses Berkshelf to fetch cookbooks, and Chef to provision the VM.

### `ec2 [PROFILE = default]`

Provision an EC2 VM using Vagrant. Same workflow as `local` using the `vagrant-aws` plugin.

### `release [PROFILE = default]`

Perform release tasks and execute Packer builds with released artifacts.

## Configuration

Configuration can be loaded from DSL files as well as JSON and command line arguments. By default, Builderator searches in your home directory (`$HOME/.builderator/Buildfile`) and the working directory (`./Builderator`) for DSL files. Configuration sources are layered and flattened into a single DSL in the following order:

* Global defaults defined in the Builderator sources
* `Config.defaults` set by plugins, tasks, etc. in code
* `$HOME/.builderator/Buildfile`
* `./Buildfile`
* `Config.overrides` set by plugins, tasks, etc. in code
* CLI arguments loaded from Thor

[Additional documentation](docs/configuration.md) describes the configuration DSL interface.

## Integrations

Builderator integrates with other tools, including [Berkshelf](http://berkshelf.com), [Vagrant](https://www.vagrantup.com/), and [Packer](https://www.packer.io/), to orchestrate workflows by generating `Berksfile`s, `Vagrantfile`s, and JSON strings for Packer. This means that you can replace all of these files in your project with a single `Buildfile`.

### Packer

The Packer integration generates Packer JSON and passes it to STDIN of `packer build -`.

    *NOTE* Currently, we assume that you're building Ubuntu images, as one of the provisioners is hard-coded to chown the Chef data directories to `ubuntu:ubuntu`
