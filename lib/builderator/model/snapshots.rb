require 'aws-sdk'
require_relative '../util'

module Builderator
  module Model

    def self.snapshots
      @snapshots ||= Snapshots.new
    end

    ##
    # EC2 Snapshot Resources
    ##
    class Snapshots < Model::Base
      LIMIT = 24
      PROPERTIES = %w(state owner_id description volume_size)

      def fetch
        @resources = {}.tap do |s|
          Util.ec2.describe_snapshots(:filters => [
            {
              :name => 'status',
              :values => %w(completed)
            }
          ], :owner_ids => ['self']).each do |page|
            page.snapshots.each do |snap|
              properties = Util.from_tags(snap.tags)
              properties['creation_date'] = snap.start_time.to_datetime
              PROPERTIES.each { |pp| properties[pp] = snap[pp.to_sym] }

              s[snap.snapshot_id] = {
                :id => snap.snapshot_id,
                :properties => properties,
                :volume => snap.volume_id
              }
            end
          end
        end
      end

      def in_use(_)
        {}.tap do |used|
          used.merge!(select(Model.volumes.snapshots))
          used.merge!(select(Model.images.snapshots))
        end
      end
    end
  end
end
