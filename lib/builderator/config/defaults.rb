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

      ## Ensure that attributes[:vendor] is a populated
      vendor() {}

      autoversion do |autoversion|
        autoversion.create_tags true
        autoversion.search_tags true
      end

      local do |local|
        local.vendor_path 'vendor'
        local.cookbook_path 'cookbooks'
      end

      chef do |chef|
        chef.log_level :info
        chef.staging_directory '/var/chef'
        chef.version = '12.5.1'
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

            ec2.region = 'us-east-1'
            ec2.instance_type 't2.micro'
            ec2.ssh_username 'ubuntu'
            ec2.ssh_host_attribute :public_ip_address
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
            build.region = 'us-east-1'
            build.instance_type 'c3.large'
            build.ami_virtualization_type 'hvm'

            build.ssh_username 'ubuntu'

            build.ami_name [Config.build_name, Config.version, Config.build_number].reject(&:nil?).join('-')
            build.ami_description Config.description
          end
        end

        profile(:bake).extends :default
      end

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

      generator.project :default do |base|
        base.builderator.version '~> 1.0'

        base.vagrant do |vagrant|
          vagrant.install false
          vagrant.version 'v1.8.0'

          vagrant.plugin 'vagrant-aws'
          vagrant.plugin 'vagrant-omnibus'
        end

        base.resource :berksfile do |berksfile|
          berksfile.path 'Berksfile', 'Berksfile.lock'
          berksfile.action :rm
        end

        base.resource :buildfile do |buildfile|
          buildfile.path 'Buildfile'
          buildfile.action :create
          buildfile.embedded 'template/Buildfile.erb'
        end

        base.resource :cookbook do |cookbook|
          cookbook.path 'cookbook'
          cookbook.action :rm
        end

        base.resource :gemfile do |gemfile|
          gemfile.path 'Gemfile'
          gemfile.action :create
          gemfile.embedded 'template/Gemfile.erb'
        end

        base.resource :gitignore do |gitignore|
          gitignore.path '.gitignore'
          gitignore.action :create
          gitignore.embedded 'template/gitignore.erb'
        end

        base.resource :packerfile do |packerfile|
          packerfile.path 'packer.json', 'packer'
          packerfile.action :rm
        end

        base.resource :rubocop do |rubocop|
          rubocop.path '.rubocop.yml'
          rubocop.action :create
          rubocop.embedded 'template/rubocop.erb'
        end

        base.resource :readme do |readme|
          readme.path 'README.md'
          readme.action :create
          readme.embedded 'template/README.md.erb'
        end

        base.resource :thorfile do |thorfile|
          thorfile.path 'Thorfile'
          thorfile.action :rm
        end

        base.resource :vagrantfile do |vagrantfile|
          vagrantfile.path 'Vagrantfile'
          vagrantfile.action :rm
        end
      end

      generator.project(:jetty).extends(:default)
    end
  end
end
