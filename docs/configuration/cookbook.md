cookbook
========

* `path` The path to a local cookbook source, including a valid `metadata.rb` file.
* `sources, type: list, singular: add_source, unique: true` Supermarket APIs to resolve cookbook dependencies from
* `metadata` Boolean. Read dependencies from local cookbook metadata.

## `depends name`

Collection of declared cookbook dependencies. Options are passed to [Berkshelf](http://berkshelf.com/). Check out their docs for additional details.

* `version` A version constraint spec for the cookbook
* `git` A git URI from which to fetch the cookbook
* `GitHub` A GitHub URL from which to fetch the cookbook
* `branch` A branch reference from which to fetch the cookbook
* `tag` A tag reference from which to fetch the cookbook
* `ref` A comittish reference from which to fetch the cookbook
* `rel` The sub-directory of a git repository to check out as a cookbook
* `path` The path to a local cookbook, relative to the build workspace.

## Tasks

* `berks metadata COOKBOOK` Generates a `metadata.json` file from a local cookbook's `metadata.rb` file. The specified `COOKBOOK` must be in the `cookbook.depends` collection with a valid `path` attribute.
* `berks vendor` Resolve and fetch cookbooks for the `cookbook.depends` collection and store in `$VENDOR_PATH/cookbooks`
* `berks upload` Upload the resolved dependency set for `cookbook.depends` to the Chef Server configured in Berkshelf's configuration (default `$HOME/.berkshelf/config.json`)
* `berks clean` Removes the project's cookbook vendor cache.
* `berks uncache` is a helper to clear Berkshelf's host-cache, in `$HOME/.berkshelf/cookbooks` by default.
