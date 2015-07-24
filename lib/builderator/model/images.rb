require 'aws-sdk'
require_relative '../util'

module Builderator
  module Model

    def self.images
      @images ||= Images.new
    end

    ##
    # Manage AusoScaling resources
    ##
    class Images < Model::Base
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
          group_by = options.fetch('group-by', [])
          groups = {}.tap do |g|
            break { 'all' => resources.values } if group_by.empty?

            resources.each do |_, image|
              (g[group_by.map do |gg|
                image[:properties].fetch(gg.to_s, '(unknown)')
              end.join(':')] ||= []) << image
            end
          end

          ## Sort each grouping
          sort_by = options.fetch('sort-by', 'creation_date')
          groups.each do |_, group|
            group.sort! { |a, b| b[:properties][sort_by] <=> a[:properties][sort_by] }
          end

          ## Slice to `keep` length
          keep = options.fetch('keep', 5)
          groups.each do |_, group|
            group.slice!(keep..-1)
          end

          ## Reduce
          groups.values.flatten.each { |i| latest[i[:id]] = i }
        end
      end

      def in_use(options = {})
        {}.tap do |used|
          used.merge!(select(Model.instances.images))
          used.merge!(select(Model.launch_configs.images))
          used.merge!(latest(options))
          used.merge!(select(used.values.map { |i| i[:parent] }))
        end
      end
    end
  end
end
