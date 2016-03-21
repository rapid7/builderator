Versioning
==========

This functionality is currently supported for Git.

## Version Bump Steps

* `major` - Increment major version.
* `major-prerelease` - Start a pre-release train from the next major version (increments major version).
* `minor` - Increment minor version.
* `minor-prerelease` - Start a pre-release train from the next minor version (increments minor version).
* `patch` - Increment the patch version.
* `patch-prerelease` - Force a new pre-release train from the next patch version, even if the current version is a pre-release.
* `release` - Release a pre-release train a the current `major`.`minor`.`patch` version.
* `prerelease NAME` Create or increment a pre-release version. If the current version is not a pre-release, the patch version will also be incremented.
* `build` Add or increment a build number.

Step types are an ordered-set. Incrementing a higher step resets all lower parameters.

## Commands

### `build version current`

Searches for the newest SCM tag that is a valid sem-ver string and writes it to VERSION in the project root.

### `build version bump [STEP [PRERELEASE_NAME=alpha]]`

Increment the current version by the desired step and create a new SCM tag at HEAD.

If STEP is omitted, Builderator will scan messages of commits between HEAD and the current version tag for hash-tag style annotations indicating how to increment the version, finally defaulting to a `patch` step if no annotations are found. If multiple `#STEP` annotations are detected, the largest (e.g. `#major` > `#patch`) step will be applied.

## Configuration

The `autoversion` namespace has two attributes:

* `create_tags BOOLEAN` enables auto-generation of SCM tags after `bump` tasks. Default `true`.
* `search_tags` enables detection of the current version from SCM tags. Default `true`.

```ruby
autoversion do |version|
  version.create_tags true
  version.search_tags true
end
```

## Adding Providers

SCM providers must extend the `Builderator::Control::Version::SCM` module, and must implement two methods in their singleton class:

* `self._history` Return an array of hashes with the following keys:
  - `:id` SCM commit identity
  - `:message` SCM commit message
  - `:tags` `nil` or an array of semver strings
* `self.supported?` Return `true` if the provider supports the build environment (e.g. the `Git` provider checks that `pwd` is a git repository), else return `false`.

To enable a provider module, pass it to `SCM.register`. See [Builderator::Control::Version::Git](blob/auto-version/lib/builderator/control/version/git.rb) for an example.

## This looks like `thor-scmversion`

_Why aren't you using `thor-scmversion`?!_

Well yes, it's based upon `thor-scmversion`, which I've been using for a while. `thor-scmversion` provides a nice model to ensure correct versioning of automatically built modules, but the project is largely abandoned, lacks some key features required for Builderator, and has a very inefficient access path for reading Git SCM data.

This implementation adds `TYPE-prerelease` bump steps, improves semver matching regular-expressions, dramatically improves git-data access time for repositories with many tags (only reads from git-blobs once),
and de-couples core functionality for parsing and incrementing versions from Thor tasks and actual mutation of the repository.
