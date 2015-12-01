require_relative './file'

module Builderator
  # :nodoc
  module Config
    ##
    # Global predefined defaults
    ##
    GLOBAL_DEFAULTS = File.new({}, :source => 'GLOBAL_DEFAULTS') do
      cleanup true
      version '0.0.0'
      build_number 0

      autoversion do |autoversion|
        autoversion.create_tags true
        autoversion.search_tags true
      end

      local do |local|
        local.vendor_path 'vendor'
        local.cookbook_path 'cookbooks'

        local.data_bag_path 'vendor/chef/data_bags'
        local.environment_path 'vendor/chef/environments'

        local.staging_directory '/var/chef'
      end

      cookbook do |cookbook|
        cookbook.path = '.'
        cookbook.add_source 'https://supermarket.chef.io'
      end

      aws.region 'us-east-1'

      profile :default do |profile|
        profile.log_level :info

        profile.vagrant do |vagrant|
          vagrant.ec2 do |ec2|
            ec2.provider :aws

            ec2.box 'dummy'
            ec2.box_url 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

            ec2.instance_type 't2.micro'
            ec2.public_ip true
          end

          vagrant.local do |local|
            local.provider :virtualbox

            local.box 'ubuntu-14.04-x86_64'
            local.box_url 'https://cloud-images.ubuntu.com/vagrant/trusty/'\
                          'current/trusty-server-cloudimg-amd64-vagrant-disk1.box'

            local.memory 1024
            local.cpus 2
          end
        end

        profile.packer do |packer|
          packer.build :default do |build|
            build.type 'amazon-ebs'
            build.instance_type 'c3.large'
            build.ssh_username 'ubuntu'
            build.virtualization_type 'hvm'

            ## The Packer task will ensure a re-compile is performed
            if Config.compiled?
              build.ami_name "#{ Config.build_name }-#{ Config.version }-#{ Config.build_number }"
              build.ami_description Config.description

              build.tags(
                :service => Config.name,
                :version => "#{ Config.version }-#{ Config.build_number }",
                :build_date => Config.date.iso8601,
                :build_url => Config.build_url,
                :parent_ami => Config.profile(build.name).packer
                                 .build(build.name).source_ami
              )
            end
          end
        end
      end

      profile(:bake).extends :default

      cleaner.limits do |limits|
        limits.images 24
        limits.launch_configs 24
        limits.snapshots 24
        limits.volumes 8
      end

      ## Ensure that attributes[:vendor] is a populated
      vendor {}
    end
  end
end
