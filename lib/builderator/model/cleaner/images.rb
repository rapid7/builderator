require 'aws-sdk'
require_relative '../../util'

module Builderator
  module Model
    module Cleaner

      def self.images
        @images ||= Images.new
      end

      ##
      # EC2 AMI Resources
      ##
      class Images < Model::Cleaner::Base
        PROPERTIES = %w(image_location state owner_id public architecture image_type
                        name description root_device_type virtualization_type
                        hypervisor)

        def fetch
          @resources = {}.tap do |i|
            Util.ec2.describe_images(:filters => [
              {
                :name => 'state',
                :values => %w(available)
              }
            ], :owners => %w(self)).each do |page|
              page.images.each do |image|
                properties = Util.from_tags(image.tags)
                properties['creation_date'] = DateTime.iso8601(image.creation_date)
                PROPERTIES.each { |pp| properties[pp] = image[pp.to_sym] }

                i[image.image_id] = {
                  :id => image.image_id,
                  :properties => properties,
                  :snapshots => image.block_device_mappings.map { |b| b.ebs.snapshot_id rescue nil }.reject(&:nil?),
                  :parent => properties.fetch('parent_ami', '(undefined)')
                }
              end
            end
          end
        end

        def snapshots
          resources.values.map { |i| i[:snapshots] }.flatten
        end

        def latest(options = {})
          {}.tap do |latest|
            ## Group images
            group_by = Config.cleaner.group_by
            groups = {}.tap do |object|
              break { 'all' => resources.values } if group_by.empty?

              resources.each do |_, image|
                ## Construct a grouping-key from image properties
                grouping_key = group_by.map do |grouping_property|
                  image[:properties].fetch(grouping_property.to_s, '(unknown)')
                end.join(':')

                ## Create an array for the group if it doesn't already exist
                ## and add the image to it
                (object[grouping_key] ||= []) << image
              end
            end

            ## Sort each grouping
            groups.each do |_, group|
              group.sort! { |a, b| b[:properties][Config.cleaner.sort_by] <=> a[:properties][Config.cleaner.sort_by] }
            end

            ## Slice to `keep` length
            groups.each do |_, group|
              group.slice!(Config.cleaner.keep..-1)
            end

            ## Reduce
            groups.values.flatten.each { |i| latest[i[:id]] = i }
          end
        end

        def in_use
          {}.tap do |used|
            used.merge!(select(Cleaner.instances.images))
            used.merge!(select(Cleaner.launch_configs.images))
            used.merge!(latest)
            used.merge!(select(used.values.map { |i| i[:parent] }))
          end
        end
      end
    end
  end
end
