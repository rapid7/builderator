Configuration DSL
=================

The configuration DSL is made up of key-value pairs, called `attributes`, which are grouped into `namespaces` and `collections`.

Namespaces can accessed with blocks, or with a fluent interface:

```ruby
aws do |a|
  a.region = 'us-west-1'
end

## Is the same as
aws.region = 'us-west-1'
```

Collections are named sets. Like namespaces, they can be accessed with blocks, or a fluent interface:

```ruby
profile :default do |default_profile|
  default_profile.chef.run_list 'apt:default', 'redis:server'
end

profile(:default).chef.environment 'development'
```

In the example above, the same collection is accessed twice. The final result looks like:

```json
{
  "profile": {
    "default": {
      "chef": {
        "run_list": ["apt:default", "redis:server"],
        "environment": "development"
      }
    }
  }
}
```

## Helper Methods

* `lookup(source, query)` - Query an external data-source for a value inline.
* Source `:image`: Return an array of EC2 instances, sorted by `creation_date` (See http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#describe_images-instance_method)

* `vendored(name, path)` - Return the absolute path to `path` in the named vendor resource. _ Hint: Use this helper to reference Builderator policy files and Chef data_bag and environment sources in an external repository._

## Configuration File DSL

Collections and namespaces may be nested indefinitely.

* [Namespace `cookbook`](configuration/cookbook.md)
* [Collection `profile`](configuration/profile.md)

* `build_name, required: true` The name of the build
* `build_number` Optional reference to the CI build number for this release
* `build_url` Optional link the CI page for this release
* `description` A short human-readable description of the build
* `version` The version of this release of the build. Auto-populated by `autoversion` by default
* `cleanup` Enable post-build cleanup tasks. Default `true`

* `relative(path)` - Return the absolute path to `path` relative to the calling Buildfile _Hint: Use this helper to reference templates included with a vendored policy._

## Namespace `autoversion`

* `create_tags` During a release, automatically create and push new SCM tags
* `search_tags` Use SCM tags to determine the current version of the build

## Namespace `chef`

Global configurations for chef provisioners in Vagrant and Packer

* `log_level` Chef client/solo log level
* `staging_directory` the path in VMs and images that Chef artifacts should be mounted/copied to. Defaults to `/var/chef`
* `version` The version of chef to install with Omnibus

## Namespace `local`

Local paths used for build tasks

* `cookbook_path` Path at which to vendor cookbooks. Default `.builderator/cookbooks`
* `data_bag_path` and `environment_path` Paths that Chef providers should load data-bag and environment documents from.

## Collection `policy`

Load additional attributes into the parent file from a relative path

* `path` Load a DSL file, relative => true
* `json` Load a JSON file relative => true

## Namespace `aws`

AWS API configurations. _Hint: Configure these in `$HOME/.builderator/Buildfile`, or use a built-in credential source, e.g. ~/.aws/config!_

* `region` The default AWS region to use
* `access_key` and `secret_key` A valid IAM key-pair

## Collection `vendor`

Fetch remote artifacts for builds

* Sources:
  * `path` Link to a local file/directory
  * `git` Fetch a git repository
  * `github` Fetch a git repository from a GitHub URI (e.g. `OWNER/REPO`) using the SSH protocol. You must have a valid SSH key configuration for public GitHub.
* Git-specific parameters:
  * `branch`
  * `tag`
  * `ref`
  * `rel` Checkout a sub-directory of a git repository

## Namespace `cleaner`

Configuration parameters for `build-clean` tasks

### Namespace `limits`

Maximum number of resources to remove without manual override

* `images`
* `launch_configs`
* `snapshots`
* `volumes`

## Namespace `generator`

Configurations for the `generator` task

### Collection `project`

* `builderator.version` The version of Builderator to install with Bundler
* `ruby.version` The version of ruby to require for Bundler and `rbenv`/`rvm`

#### Namespace `vagrant`

* `install` Boolean, include the vagrant gem from GitHub `mitchellh/vagrant`
* `version` The version of Vagrant to use from GitHub, if `install` is true

##### Collection `plugin`

Vagrant plugins to install, either with the `build vagrant plugin` command, for a system-wide installation of Vagrant, or in the generated Gemfile if `install` is true

#### Collection `resource`

Add a managed file to the project definition

* `action` One of
  * `:create` Add a file from a template if it's missing
  * `:sync` Create or update a file from a template, stopping to ask for instructions if the file exists and the templated output does not match
  * `:ignore` Do nothing
  * `:rm` Delete a file if it exists
* `path` One or more path in the working directory the this resource manages. Action `:rm` will delete multiple files, while `:create` and `:sync` will only use the first element of the list as their destination.
* `template` The path to an ERB template. Must be an absolute path: use the [helpers](#helpers) in the Buildfile namespace to extend paths inline.
