require 'aws-sdk'
require_relative '../util'

module Builderator
  module Model

    def self.launch_configs
      @launch_configs ||= LaunchConfigs.new
    end

    ##
    # ASG LaunchConfiguration Resources
    ##
    class LaunchConfigs < Model::Base
      LIMIT = 24
      PROPERTIES = %w(launch_configuration_arn key_name security_groups
                      user_data instance_type spot_price iam_instance_profile
                      ebs_optimized associate_public_ip_address placement_tenancy)

      def fetch
        @resources = {}.tap do |i|
          Util.asg.describe_launch_configurations.each do |page|
            page.launch_configurations.each do |l|
              properties = { 'creation_date' => l.created_time.to_datetime }
              PROPERTIES.each { |pp| properties[pp] = l[pp.to_sym] }

              i[l.launch_configuration_name] = {
                :id => l.launch_configuration_name,
                :properties => properties,
                :image => l.image_id
              }
            end
          end
        end
      end

      def images
        resources.values.map { |l| l[:image] }
      end

      def in_use(_)
        select(Model.scaling_groups.launch_configs)
      end
    end
  end
end
