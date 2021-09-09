require_relative './file'
require_relative '../util'

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
        autoversion.create_tags false
        autoversion.search_tags true
      end

      local do |local|
        local.cookbook_path Util.workspace('cookbooks')
      end

      chef do |chef|
        chef.log_level :info
        chef.staging_directory '/var/chef'
        chef.version = '15.3'
      end

      cookbook do |cookbook|
        cookbook.path = '.'
        cookbook.add_source 'https://supermarket.chef.io'
      end

      berkshelf do |berkshelf|
        berkshelf.solver :gecode
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

            ## Atlas metadata for Ubuntu cloud-images: https://atlas.hashicorp.com/ubuntu/boxes/trusty64
            local.box 'ubuntu/bionic64'

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

            # Packer default is 300 seconds.  Specify as a string to give units
            # such as s (seconds), ms (milliseconds), ns (nanoseconds), etc.
            # Ints will be interpreted as ns.  Buyer beware.
            build.ssh_timeout '300s'

            # Clear the AMI and launch block device mappings for the default
            # c3.large instance type.
            build.ami_block_device_mappings [{
              'device_name' => '/dev/sdb',
              'no_device' => true,
            }, {
              'device_name' => '/dev/sdc',
              'no_device' => true,
            }]
            build.launch_block_device_mappings [{
              'device_name' => '/dev/sdb',
              'no_device' => true,
            }, {
              'device_name' => '/dev/sdc',
              'no_device' => true,
            }]

            build.ami_name [Config.build_name, Config.version, Config.build_number].reject(&:nil?).join('-')
            build.ami_description Config.description
          end
        end
      end

      profile :docker do |profile|
        profile.log_level :info

        profile.packer do |packer|
          packer.build :docker do |build|
            build.type 'docker'
          end
        end
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

      generator.project :default do |default|
        default.builderator.version '~> 1.0'

        default.vagrant do |vagrant|
          vagrant.install false
          vagrant.version 'v1.8.0'

          vagrant.plugin 'vagrant-aws'
          vagrant.plugin 'vagrant-omnibus'
        end

        default.resource :berksfile do |berksfile|
          berksfile.path 'Berksfile', 'Berksfile.lock'
          berksfile.action :rm
        end

        default.resource :buildfile do |buildfile|
          buildfile.path 'Buildfile'
          buildfile.action :create
          buildfile.template 'template/Buildfile.erb'
        end

        default.resource :cookbook do |cookbook|
          cookbook.path 'cookbook'
          cookbook.action :rm
        end

        default.resource :gemfile do |gemfile|
          gemfile.path 'Gemfile'
          gemfile.action :create
          gemfile.template 'template/Gemfile.erb'
        end

        default.resource :gitignore do |gitignore|
          gitignore.path '.gitignore'
          gitignore.action :create
          gitignore.template 'template/gitignore.erb'
        end

        default.resource :packerfile do |packerfile|
          packerfile.path 'packer.json', 'packer'
          packerfile.action :rm
        end

        default.resource :rubocop do |rubocop|
          rubocop.path '.rubocop.yml'
          rubocop.action :create
          rubocop.template 'template/rubocop.erb'
        end

        default.resource :readme do |readme|
          readme.path 'README.md'
          readme.action :create
          readme.template 'template/README.md.erb'
        end

        default.resource :thorfile do |thorfile|
          thorfile.path 'Thorfile'
          thorfile.action :rm
        end

        default.resource :vagrantfile do |vagrantfile|
          vagrantfile.path 'Vagrantfile'
          vagrantfile.action :rm
        end
      end
    end
  end
end
