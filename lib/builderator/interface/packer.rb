require_relative '../config'
require_relative '../interface'
require_relative '../util'

module Builderator
  class Interface
    class << self
      def packer(profile = :default)
        @packer ||= {}
        @packer[profile] ||= Packer.new(profile)
      end
    end

    ##
    # Generate packer.json
    ##
    class Packer < Interface
      def initialize(profile = :default)
        super

        date Config.date

        builders Config.profile(profile).packer.build.values
        artifact.includes Config.profile(profile).artifact

        builders.each do |builder|
          builder.tags = Config.profile(profile).tags
        end

        chef do |chef|
          chef.includes Config.local
          chef.includes Config.profile(profile).chef
        end
      end

      attribute :date
      attribute :builders, :type => :list, :singular => :builder

      collection :artifact do
        attribute :path
        attribute :destination
      end

      namespace :chef do
        attribute :cookbook_path
        attribute :data_bag_path
        attribute :environment_path
        attribute :staging_directory

        attribute :run_list, :type => :list, :singular => :run_list_item
        attribute :environment
        attribute :node_attrs
      end

      def write
        packer_json = {
          :builders => builders,
          :provisioners => [{
            :type => 'shell',
            :inline => "mkdir -p #{chef.staging_directory}/cache && chown ubuntu:ubuntu -R #{chef.staging_directory}"
          }]
        }

        artifact.each do |_, artifact|
          packer_json[:provisioners] << {
            :type => 'file',
            :source => artifact.path,
            :destination => artifact.destination
          }
        end

        packer_json[:provisioners] << {
          :type => 'chef-solo',
          :run_list => chef.run_list,
          :cookbook_paths => [chef.cookbook_path],
          :data_bags_path => chef.data_bag_path,
          :environments_path => chef.environment_path,
          :chef_environment => chef.environment,
          :json => chef.node_attrs,
          :staging_directory => chef.staging_directory
        }

        JSON.pretty_generate(packer_json)
      end
    end
  end
end
