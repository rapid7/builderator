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

Collections and namespaces may be nested indefinitely.

* [Namespace `cookbook`](configuration/cookbook.md)
* [Collection `profile`](configuration/profile.md)

* `build_name, required: true` The name of the build
* `build_number` Optional reference to the CI build number for this release
* `build_url` Optional link the CI page for this release
* `description` A short human-readable description of the build
* `version` The version of this release of the build. Auto-populated by `autoversion` by default
* `cleanup` Enable post-build cleanup tasks. Default `true`

## Namespace `autoversion`

* `create_tags` During a release, automatically create and push new SCM tags
* `search_tags` Use SCM tags to determine the current version of the build

## Namespace `local`

Local paths used for build tasks

* `vendor_path` The workspace-rooted path at which to store vendored artifacts. Default `.builderator/vendor`
* `cookbook_path` The workspace-rooted path at which to vendor cookbooks. Default `.builderator/cookbooks`
* `data_bag_path` and `environment_path` Workspace-rooted paths that Chef providers should load data-bag and environment documents from. Defaults to `.builderator/vendor/chef`. This assumes that you provide a `chef` vendor that fetches a valid Chef-Repo with valid `data_bags` and `environments` directories.
* `staging_directory` the path in VMs and images that Chef artifacts should be mounted/copied to. Defaults to `/var/chef`

## Namespace `aws`

AWS API configurations. _Hint: Configure these in `$HOME/.builderator/Buildfile`!_

* `region` The default AWS region to use
* `access_key` and `secret_key` A valid IAM key-pair

## Collection `vendor`

Fetch remote artifacts for builds

* `path` link to a local file/directory
* `git`, `GitHub` Fetch a git repository
* `branch`
* `tag`
* `ref`
* `rel` Checkout a sub-directory of

## Namespace `cleaner`

Configuration parameters for `build-clean` tasks

### Namespace `limits`

Maximum number of resources to remove without manual override

* `images`
* `launch_configs`
* `snapshots`
* `volumes`
