# Builderator

Orchestration and configuration of the code development life-cycle.

## Commands

Run `build help` for a complete enumeration of Builderator's commands.

### `local [PROFILE = default]`

Provision a local VM using Vagrant and, by default, VirtualBox. Uses Berkshelf to fetch cookbooks, and Chef to provision the VM.

### `ec2 [PROFILE = default]`

Provision an EC2 VM using Vagrant. Same workflow as `local` using the `vagrant-aws` plugin.

### `image [PROFILE = default]`

Use [Packer](https://www.packer.io) to build an image(s) for the specified profile.

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

The Packer integration generates a Packer JSON configuration and passes it to STDIN of `packer build -`.

### Vagrant

Builderator shells out to Vagrant to provision VMs on demand. Run

```sh
build vagrant plugins
```

to install required plugins for Builderator.

## Versioning

Builderator can automatically detect versions from SCM tags, increment the latest version of an SCM branch by a variety of steps, and create new SCM tags for new versions.

[Additional documentation](docs/versioning.md) describes CLI commands, configuration, and detailed behavior.

## Generators

Builderator includes a task to generate common project trees from configuration definitions  and templates.

Each type of project is configurable via the project collection in the `generator` namespace:

```ruby
generator.project :default do |default|
  default.ruby.version '2.1.5'
  default.builderator.version '~> 1.0'

  default.vagrant do |vagrant|
    vagrant.install false
    vagrant.version 'v1.8.0'

    vagrant.plugin 'vagrant-aws'
    vagrant.plugin 'vagrant-omnibus'
  end

  default.resource :berksfile do |berksfile|
    berksfile.path 'Berksfile', 'Berksfile.lock'
    berksfile.action :rm
  end

  default.resource :buildfile do |buildfile|
    buildfile.path 'Buildfile'
    buildfile.action :create
    buildfile.template 'template/Buildfile.erb'
  end

  # ...
end
```

Valid actions for resources include `:ignore`, `:create` (update only if missing), `:sync` (create or update with prompt), and `:rm`. `:create` and `:sync` actions require a valid template source.

By default, the `generator` subcommand includes a `default` project which removes Vagrant, Berkshelf, and Packer configurations.

## Utilities

Builderator includes two utilities to search for and clean up EC2 resources.

### `build-clean`

The `build-clean` command prunes old EC2 resources in a region. The cleaner utility has [configurable](docs/configuration.md#namespace-cleaner) limits. For complete usage, run `build-clean help`.

### `build-data`

The `build-data` utility is a command line interface for Builderator's internal resource lookup API. It has a limited query interface that allows filters to be constructed from a trailing list of argument:

```sh
build-data image architecture x86_64 virtualization-type hvm ...
```

Pre-defined filters can also be applied with the `-f FILTER` flag. These currently include

* `ubuntu-14.04-daily`
* `windows-server2012-r2`
* `windows-server2012-r2-core`

Run `build-data help` for a complete listing of commands and arguments.
