require 'aws-sdk'
require_relative '../../util'

module Builderator
  module Model
    # :nodoc:
    module Cleaner
      def self.instances
        @instances ||= Instances.new
      end

      ##
      # EC2 Instance resources
      ##
      class Instances < Model::Cleaner::Base
        PROPERTIES = %w(private_dns_name public_dns_name instance_type
                        subnet_id vpc_id private_ip_address public_ip_address
                        architecture root_device_type virtualization_type
                        hypervisor)

        def fetch
          @resources = {}.tap do |i|
            Util.ec2.describe_instances(:filters => [
              {
                :name => 'instance-state-name',
                :values => %w(pending running shutting-down stopping stopped)
              }
            ]).each do |page|
              page.reservations.each do |r|
                r.instances.each do |instance|
                  properties = Util.from_tags(instance.tags)
                  properties['availability_zone'] = instance.placement.availability_zone
                  properties['creation_date'] = instance.launch_time.to_datetime
                  PROPERTIES.each { |pp| properties[pp] = instance[pp.to_sym] }

                  i[instance.instance_id] = {
                    :id => instance.instance_id,
                    :image => instance.image_id,
                    :volumes => instance.block_device_mappings.map { |b| b.ebs.volume_id },
                    :properties => properties
                  }
                end
              end
            end
          end
        end

        def images
          resources.values.map { |i| i[:image] }
        end

        def volumes
          resources.values.map { |i| i[:volumes] }.flatten
        end
      end
    end
  end
end
