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

## Versioning

Builderator can automatically detect versions from SCM tags, increment the latest version of an SCM branch by a variety of steps, and create new SCM tags for new versions.

[Additional documentation](docs/versioning.md) describes CLI commands, configuration, and detailed behavior.

## Generators

Builderator includes tasks to generate common project configurations. The `Generator::Base` class is a Group of base steps to create/remove files common to many types of projects. `Generator::Jetty` extends `Base` to manage additional files specific to Jetty/JVM projects.

Each type of project is configurable via collections in the `generator` namespace. Defaults are

```ruby
      generator.project :jetty do |jetty|
        jetty.build_version '~> 1.0'
        jetty.vagrant_install true
        jetty.vagrant_version 'v1.7.4'

        ## Task flags
        jetty.berksfile :rm
        jetty.buildfile :create
        jetty.cookbook :rm
        jetty.gemfile :create
        jetty.gitignore :create
        jetty.packerfile :rm
        jetty.rubocop :create
        jetty.readme :create
        jetty.vagrantfile :rm
        jetty.thorfile :rm
      end
```

Valid actions for templates include `:ignore`, `:create` (update only if missing), `:sync` (create or update with prompt), and `:rm`. For some resources without templates, only the `:rm` action will have an effect.

The `generator` subcommand includes `base` and `jetty` tasks.
