require 'time'

require_relative './attributes'
require_relative '../control/data'
require_relative '../util'

# rubocop:disable Metrics/ClassLength

module Builderator
  module Config
    ##
    # DSL Loader for a configuration file
    ##
    class File < Attributes
      class << self
        ## DSL Loaders
        def from_file(source, **options)
          new({}, options.merge(:type => :file, :source => source))
        end

        def from_json(source, **options)
          new({}, options.merge(:type => :json, :source => source))
        end

        def lookup_cache
          @lookup_cache ||= {}
        end
      end

      attr_reader :date ## Provide an authoritative, UTC-based date for any consumers
      attr_reader :source ## Where the instance was defined
      attr_reader :type ## How compile should populate attributes

      def initialize(attributes = {}, options = {}, &block)
        super(attributes, &block)

        @date = Time.now.utc
        @type = options.fetch(:type, :code)
        @source = options.fetch(:source, nil)
      end

      def compile
        clean ## Clear dirty flag before re-parsing file or block

        case @type
        when :file
          instance_eval(IO.read(source), source, 0)
        when :json
          @attributes = Rash.coerce(JSON.parse(IO.read(source)))
        else
          instance_eval(&@block) if @block
        end

        self
      end

      ## Use the Data controller to fetch IDs from the EC2 API at compile time
      def lookup(source, query)
        self.class.lookup_cache[_lookup_cache_key(query)] ||= Control::Data.lookup(source, query)
      end

      def _lookup_cache_key(query)
        query.keys.sort.map { |k| "#{k}:#{query[k]}" }.join('|')
      end

      attribute :build_name, :required => true
      attribute :build_number
      attribute :build_url

      attribute :description
      attribute :version

      ##
      # Enable/disable auto-versioning features
      ##
      namespace :autoversion do
        attribute :create_tags
        attribute :search_tags
      end

      ##
      # Local resource paths
      ##
      namespace :local do
        attribute :vendor_path, :workspace => true
        attribute :cookbook_path, :workspace => true

        attribute :data_bag_path, :workspace => true
        attribute :environment_path, :workspace => true

        attribute :staging_directory
      end

      ##
      # Cookbook build options
      ##
      namespace :cookbook do
        attribute :path
        attribute :berkshelf_config

        attribute :sources, :type => :list, :singular => :add_source
        attribute :metadata

        collection :depends do
          attribute :version

          attribute :git
          attribute :github
          attribute :branch
          attribute :tag
          attribute :ref
          attribute :rel

          attribute :path, :relative => true
        end
      end

      ##
      # AWS configurations
      ##
      namespace :aws do
        attribute :region
        attribute :access_key
        attribute :secret_key
      end

      collection :profile do
        attribute :tags, :type => :hash
        attribute :log_level

        ##
        # Sync'd artifacts
        ##
        collection :artifact do
          attribute :path, :relative => true
          attribute :destination
        end

        ##
        # Chef configurations
        ##
        namespace :chef do
          attribute :run_list, :type => :list, :singular => :run_list_item
          attribute :environment
          attribute :node_attrs
        end

        ##
        # Packerfile
        #
        # This currently supports the AWS/EC2 builder.
        ##
        namespace :packer do
          collection :build do
            attribute :type

            ## EC2 Placement and Virtualization parameters
            attribute :region
            attribute :availability_zone
            attribute :vpc_id
            attribute :subnet_id

            attribute :instance_type
            attribute :ami_virtualization_type
            attribute :enhanced_networking
            attribute :security_group_ids, :type => :list, :singular => :security_group_id
            attribute :iam_instance_profile

            attribute :source_ami
            attribute :user_data
            attribute :user_data_file

            attribute :windows_password_timeout

            ## Access parameters
            attribute :ssh_username
            attribute :ssh_keypair_name
            attribute :ssh_private_key_file
            attribute :ssh_private_ip
            attribute :temporary_key_pair_name

            attribute :ami_name
            attribute :ami_description
            attribute :ami_users, :type => :list
            attribute :ami_regions, :type => :list
          end
        end

        ##
        # Vagrantfile
        ##
        namespace :vagrant do
          namespace :local do
            attribute :provider
            attribute :box
            attribute :box_url

            attribute :cpus
            attribute :memory
          end

          namespace :ec2 do
            attribute :provider
            attribute :box
            attribute :box_url

            attribute :region
            attribute :availability_zone
            attribute :subnet_id
            attribute :private_ip_address

            attribute :instance_type
            attribute :security_groups, :type => :list
            attribute :iam_instance_profile_arn

            attribute :source_ami
            attribute :user_data

            attribute :ssh_username
            attribute :keypair_name
            attribute :private_key_path

            attribute :associate_public_ip
            attribute :ssh_host_attribute
            attribute :instance_ready_timeout
            attribute :instance_check_interval
          end
        end
      end

      ##
      # Configure resources that must be fetched for a build
      ##
      collection :vendor do
        attribute :path

        attribute :git
        attribute :github
        attribute :branch
        attribute :tag
        attribute :ref
        attribute :rel
      end

      ##
      # Cleaner Parameters
      ##
      namespace :cleaner do
        attribute :commit
        attribute :force
        attribute :filters, Hash
        attribute :group_by, :type => :list
        attribute :sort_by
        attribute :keep

        namespace :limits do
          attribute :images
          attribute :launch_configs
          attribute :snapshots
          attribute :volumes
        end
      end

      ##
      # Generator Options
      ##
      namespace :generator do
        collection :project do
          attribute :berksfile
          attribute :buildfile
          attribute :gemfile
          attribute :gitignore
          attribute :packerfile
          attribute :rubocop
          attribute :readme
          attribute :thorfile
          attribute :vagrantfile
          attribute :cookbook
        end

        namespace :ruby do
          attribute :version
        end

        attribute :version

        namespace :gemfile do
          namespace :vagrant do
            attribute :install
            attribute :version
          end
        end
      end

      ##
      # Option to disable cleanup of build resources
      ##
      attribute :cleanup
    end
  end
end

# rubocop:enable Metrics/ClassLength
