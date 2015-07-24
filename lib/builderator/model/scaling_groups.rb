require 'aws-sdk'
require_relative '../util'

module Builderator
  module Model

    def self.scaling_groups
      @scaling_groups ||= ScalingGroups.new
    end

    ##
    # Manage AusoScaling resources
    ##
    class ScalingGroups < Model::Base
      attr_reader :resources
      PROPERTIES = %w(auto_scaling_group_arn min_size max_size desired_capacity
                      default_cooldown availability_zones load_balancer_names
                      vpc_zone_identifier status termination_policies)

      def fetch
        @resources = {}.tap do |i|
          Util.asg.describe_auto_scaling_groups.each do |page|
            page.auto_scaling_groups.each do |a|
              properties = Util.from_tags(a.tags)
              properties['creation_date'] = a.created_time.to_datetime
              PROPERTIES.each { |pp| properties[pp] = a[pp.to_sym] }

              i[a.launch_configuration_name] = {
                :id => a.auto_scaling_group_name,
                :properties => properties,
                :config => a.launch_configuration_name
              }
            end
          end
        end
      end

      def launch_configs
        resources.values.map { |g| g[:config] }
      end
    end
  end
end
