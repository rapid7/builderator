require 'aws-sdk'
require_relative '../util'

module Builderator
  module Model

    def self.volumes
      @volumes ||= Volumes.new
    end

    ##
    # EC2 Volume Resources
    ##
    class Volumes < Model::Base
      LIMIT = 8
      PROPERTIES = %w(size availability_zone state volume_type iops)

      def fetch
        @resources = {}.tap do |v|
          Util.ec2.describe_volumes.each do |page|
            page.volumes.each do |vol|
              properties = Util.from_tags(vol.tags)
              properties['creation_date'] = vol.create_time.to_datetime
              PROPERTIES.each { |pp| properties[pp] = vol[pp.to_sym] }


              v[vol.volume_id] = {
                :id => vol.volume_id,
                :properties => properties,
                :snapshot => vol.snapshot_id
              }
            end
          end
        end
      end

      def snapshots
        resources.values.map { |v| v[:snapshot] }
      end

      def in_use(_)
        {}.tap do |used|
          used.merge!(select(Model.instances.volumes))
        end
      end
    end
  end
end
