Collection `profile`
====================

A profile is a combination of Chef parameters, and Vagrant and Packer configurations. Profiles should provide

* `tags, type: hash` EC2 tags to apply to instances and AMIs
* `log_level` Chef log-level. Default `:info`

## Collection `artifact`

An externally managed resource to push to VMs and image builds, e.g. `bundle.tar.gz` from a Maven build.

* `path` The workspace-rooted path to the artifact
* `destination` The absolute path on the VM or image at which the artifact should be placed

## Namespace `chef`
* `run_list, type: list, singular: run_list_item, unique: true` The Chef runlist for this profile
* `environment` The Chef environment to load for this
* `node_attrs, type: hash` A hash of node attributes for this profile
* `binary_env` A space separated, KEY=VALUE formatted string to pass data
    into the provisioning process as environment variables. See
    [the vagrant docs](https://www.vagrantup.com/docs/provisioning/chef_common.html#binary_env)
    for more information.

## Collection `provisioner`

Packer/Vagrant provisioner definitions. Currently only supports inline shell provisioners.

* `inline, type: list` A list of shell provisioners
* `environment_vars, type: list` A list of environment vars (in `KEY=VALUE` format) to pass to the shell script

## Namespace `packer`

Packer configurations for this profile

### Collection `build`

Add a Packer build

* `type` the build provider (e.g. amazon-ebs, virtualbox, docker)

Options for the `docker` builder:

* `image` The base image for the Docker container that will be started

The Docker builder requires one, and only one, of the following options:

* `commit` The container will be committed to an image rather than exported
* `discard` Throw away the container when the build is complete
* `export_path` The path where the final container will be exported as a tar file

There are additional options specified in [`lib/builderator/config/file.rb`](../../lib/builderator/config/file.rb) and
in the Packer documentation.

Options for the `amazon-ebs` builder:

* `instance_type` the EC2 instance type to use
* `source_ami` The source AMI ID for an `amazon-ebs`
* `ssh_username` Default `ubuntu`
* `ami_virtualization_type` Default `hvm`
* `tagging_role` the name of an IAM role that exists in each remote account that allows the AMI to be retagged

  Example usage:

  <pre>
     profile bake: Config.profile(:default) do |bake|
       bake.packer do |packer|
         packer.build :default do |build|
           build.tagging_role 'CreateTagsOnAllImages'
         end
       end
     end
  </pre>

  Example IAM policy in remote account:

  <pre>
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "StmtId",
              "Effect": "Allow",
              "Action": [
                  "ec2:CreateTags"
              ],
              "Resource": [
                  "*"
              ]
          }
      ]
  }
  </pre>


  The above policy needs to be assigned to a role that enables a trust relationship with the account that builds the AMI:

  <pre>
  {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
              "AWS": "arn:aws:iam::[ami_builder_account]:user/[ami_builder_user]"
            },
            "Action": "sts:AssumeRole"
        }
  }
  </pre>

### Attribute `post_processors`

Add a packer post-processor to run after the provisioning steps. This is a free-form
attribute as there is no validation of elements defined here. If invalid configuration
is supplied, errors will only appear when Packer tries to execute them.

The `post_processors` attribute supports simple, complex, and sequence definitions.

Example:

```ruby
packer.post_processors [
  [
    # Complex
    {
      :type => 'docker-tag',
      :repository => 'rapid7/builderator',
      :tag => '1.2.2'
    },

    'docker-push' # Simple
  ],

  # Sequence
  [
    {
      :type => 'docker-tag',
      :repository => 'rapid7/builderator',
      :tag => 'latest'
    },
    'docker-push'
  ]
]
```


## TODO: Share accounts

* `ami_name` Name for new AMI
* `ami_description` Description for the new AMI


## Namespace `vagrant`

Vagrant VM configurations

### Namespace `local`

Parameters for a local VM build

* `provider` Default `virtualbox`
* `box` Default `ubuntu-14.04-x86_64`
* `box_url` Default `https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box`

* `cpus` Default 2
* `memory` Default 1024 (MB)

## Namespace `ec2`

Parameters for the provisioning EC2 nodes with Vagrant

* `provider` Default `aws`
* `box` Default `dummy`
* `box_url` Default `https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box`
* `instance_type`
* `source_ami`
* `ssh_username`
* `virtualization_type`
* `iam_instance_profile_arn`
* `subnet_id`
* `security_groups, type: list, singular: security_group, unique: true`
* `public_ip`
* `ssh_host_attribute` One of: `[:public_ip_address, :dns_name, :private_ip_address]`, Default `:private_ip_address`

[docker-tag]: https://www.packer.io/docs/post-processors/docker-tag.html
[docker-import]: https://www.packer.io/docs/post-processors/docker-import.html
[docker-save]: https://www.packer.io/docs/post-processors/docker-save.html
[docker-push]: https://www.packer.io/docs/post-processors/docker-push.html
