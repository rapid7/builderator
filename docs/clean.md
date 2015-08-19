build-clean
===========
Tasks to delete/deregister abandoned EC2 resources

### Options
* `--commit` Execute cleanup task. Default behavior is to display resources that would be removed
* `--filter KEY VALUE [KEY VALUE []]` Key/value pairs to filter resources. Valid keys include tags and native resource properties (See `describe` responses in the Ruby AWS-SDK)

### Commands
* `configs` Delete launch configurations that are not associated with an autoscaling group.

* `images` Delete images that are not associated with a launch configuration, a running instance, or are tagged as the 'parent' of an image that qualifies for any of the previous three conditions. Additionally, a fixed number of images can be retained per ordered groups.

  **Options**
  * `--group-by KEY [KEY []]` Tags/properties to group images by for pruning
  * `--sort-by KEY` Tag/property to sort grouped images on (Default: creation_date)
  * `--keep N` Number of images in each group to keep (Default: 0)

* `snapshots` Delete snapshots that are not associated with existing volumes or images.

* `volumes` Delete volumes that are not attached to instances.
