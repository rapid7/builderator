require 'aws-sdk'

require_relative '../util'
require_relative './ec2'

module Builderator
  module Control
    ##
    # Manage AusoScaling resources
    ##
    module ASG
      class << self
        def launch_configs(update = false)
          return @configs unless @configs.nil? || update

          @configs = {}.tap do |configs|
            Builderator::Util.asg.describe_launch_configurations.each do |page|
              page.launch_configurations.each do |lc|
                configs[lc.launch_configuration_name] = lc
              end
            end
          end
        end

        def scaling_groups(update = false)
          return @groups unless @groups.nil? || update

          @groups = {}.tap do |groups|
            Builderator::Util.asg.describe_auto_scaling_groups.each do |page|
              page.auto_scaling_groups.each do |asg|
                groups[asg.auto_scaling_group_name] = asg
              end
            end
          end
        end

        def active_launch_configs(update = false)
          return @active_launch_configs unless @active_launch_configs.nil? || update

          @active_launch_configs = {}.tap do |configs|
            launch_configs(true) if update
            scaling_groups(update).each do |_, asg|
              configs[asg.launch_configuration_name] = launch_configs[asg.launch_configuration_name]
            end
          end
        end

        def unused_launch_configs(update = false)
          return @unused_launch_configs unless @unused_launch_configs.nil? || update

          @unused_launch_configs = {}.tap do |configs|
            (launch_configs(update).keys - active_launch_configs(update).keys).each do |lc|
              configs[lc] = launch_configs[lc]
            end
          end
        end

        def active_images(options = {}, update = false)
          return @active_images unless @active_images.nil? || update

          @active_images = {}.tap do |active|
            images = Control::EC2.images(options, update)
            active_launch_configs(update).each do |_, lc|
              active[lc.image_id] = images[lc.image_id] if images.include?(lc.image_id)
            end
          end
        end
      end
    end
  end
end
