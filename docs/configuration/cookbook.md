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
