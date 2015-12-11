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
        local.staging_directory '/var/chef'
      end

      cookbook do |cookbook|
        cookbook.path = '.'
        cookbook.berkshelf_config = ::File.join(ENV['HOME'], '.berkshelf/config.json')
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
            build.ami_virtualization_type 'hvm'
            build.ami_name [Config.build_name, Config.version, Config.build_number].reject(&:nil?).join('-')
            build.ami_description Config.description
          end
        end
      end

      profile(:bake).extends :default

      cleaner do |cleaner|
        cleaner.commit false
        cleaner.force false
        cleaner.filters {}
        cleaner.sort_by 'creation_date'
        cleaner.keep 5

        cleaner.limits do |limits|
          limits.images 24
          limits.launch_configs 48
          limits.snapshots 24
          limits.volumes 8
        end
      end

      generator.gemfile.vagrant do |vagrant|
        vagrant.install true
        vagrant.version 'v1.7.4'
      end

      generator.project :jetty do |jetty|
        jetty.berksfile :rm
        jetty.buildfile :create
        jetty.gemfile :create
        jetty.gitignore :create
        jetty.rubocop :create
        jetty.packerfile :rm
        jetty.vagrantfile :rm
        jetty.thorfile :rm

        jetty.cookbook :rm
      end

      ## Ensure that attributes[:vendor] is a populated
      vendor {}
    end
  end
end
