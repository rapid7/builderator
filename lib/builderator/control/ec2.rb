require 'aws-sdk'

require_relative '../util'
require_relative './asg'

module Builderator
  module Control
    ##
    # Manage AusoScaling resources
    ##
    module EC2
      class << self
        def volumes(options = {}, update = false)
          @volumes ||= {}
          @volumes.tap do |v|
            Builderator::Util.ec2.describe_volumes.each do |page|
              page.volumes.each do |vol|
                properties = Builderator::Util.from_tags(vol.tags)
                properties['creation_date'] = vol.create_time.to_datetime
                %w(size availability_zone state volume_type iops).each { |pp| properties[pp] = vol[pp.to_sym] }

                v[vol.volume_id] = {
                  :id => vol.volume_id,
                  :properties => properties,
                  :snapshot => vol.snapshot_id
                }
              end
            end
          end if @volumes.empty? || update

          ## Apply filters
          filters = Hash[*options.fetch('filter', [])]
          @volumes.select do |_, vol|
            filters.reduce(true) do |memo, (k, v)|
              memo && vol[:properties].include?(k.to_s) &&
                vol[:properties][k.to_s] == v
            end
          end
        end

        def snapshots(options = {}, update = false)
          @snapshots ||= {}
          @snapshots.tap do |s|
            Builderator::Util.ec2.describe_snapshots(:filters => [
              {
                :name => 'status',
                :values => %w(completed)
              }
            ]).each do |page|
              page.snapshots.each do |snap|
                properties = Builderator::Util.from_tags(snap.tags)
                properties['creation_date'] = snap.start_time.to_datetime
                %w(state owner_id description volume_size).each { |pp| properties[pp] = snap[pp.to_sym] }

                s[snap.snapshot_id] = {
                  :id => snap.snapshot_id,
                  :properties => properties,
                  :volume => snap.volume_id
                }
              end
            end
          end if @snapshots.empty? || update

          ## Apply filters
          filters = Hash[*options.fetch('filter', [])]
          @snapshots.select do |_, snap|
            filters.reduce(true) do |memo, (k, v)|
              memo && snap[:properties].include?(k.to_s) &&
                snap[:properties][k.to_s] == v
            end
          end
        end

        def images(options = {}, update = false)
          @images ||= {}
          @images.tap do |i|
            Builderator::Util.ec2.describe_images(:filters => [
              {
                :name => 'state',
                :values => %w(available)
              }
            ], :owners => %w(self)).each do |page|
              page.images.each do |image|
                properties = Builderator::Util.from_tags(image.tags)
                properties['creation_date'] = DateTime.iso8601(image.creation_date)
                %w(image_location state owner_id public architecture image_type
                   name description root_device_type virtualization_type
                   hypervisor).each { |pp| properties[pp] = image[pp.to_sym] }

                i[image.image_id] = {
                  :id => image.image_id,
                  :properties => properties,
                  :snapshots => image.block_device_mappings.map { |b| b.ebs.snapshot_id rescue nil }.reject(&:nil?),
                  :parent => properties.fetch('parent_ami', '(undefined)')
                }
              end
            end if @images.empty? || update
          end

          ## Apply filters
          filters = Hash[*options.fetch('filter', [])]
          @images.select do |_, image|
            filters.reduce(true) do |memo, (k, v)|
              memo && image[:properties].include?(k.to_s) &&
                image[:properties][k.to_s] == v
            end
          end
        end

        def instances(update = false)
          return @instances unless @instances.nil? || update

          @instances = {}.tap do |i|
            Builderator::Util.ec2.describe_instances(:filters => [
              {
                :name => 'instance-state-name',
                :values => %w(pending running shutting-down stopping stopped)
              }
            ]).each do |page|
              page.reservations.each do |r|
                r.instances.each do |instance|
                  i[instance.instance_id] = {
                    :id => instance.instance_id,
                    :image => instance.image_id,
                    :properties => Builderator::Util.from_tags(instance.tags)
                  }
                end
              end
            end
          end
        end

        def latest_images(options = {}, update = false)
          return @latest_images unless @latest_images.nil?
          @latest_images = {}.tap do |latest|
            ## Group images
            group_by = options.fetch('group-by', [])
            groups = {}.tap do |g|
              break { 'all' => images(options, update).values } if group_by.empty?

              images(options, update).each do |_, image|
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

            ## Slice to keep length
            keep = options.fetch('keep', 5)
            groups.each do |_, group|
              group.slice!(keep..-1)
            end

            ## Reduce
            groups.values.flatten.each { |i| latest[i[:id]] = i }
          end
        end

        def active_images(options = {}, update = false)
          return @active_images unless @active_images.nil? || update

          @active_images = {}.tap do |active|
            instances(update).each do |_, instance|
              active[instance[:image]] = images[instance[:image]] if
                images.include?(instance[:image])

              active[instance[:parent]] = images[instance[:parent]] if
                instance.include?(:parent) &&
                images.include?(instance[:parent])

              active.merge!(Control::ASG.active_images(options, update))
              active.merge!(latest_images(options, update))
            end
          end
        end

        def unused_images(options = {}, update = false)
          return @unused_images unless @unused_images.nil? || update

          @unused_images = {}.tap do |unused|
            (images(options, update).keys - active_images(options, update).keys).each do |i|
              unused[i] = images[i] if images.include?(i)
            end
          end
        end

        def active_snapshots(options = {}, update = false)
          return @active_snapshots unless @active_snapshots.nil? || update

          @active_snapshots = {}.tap do |active|
            snapshots(options, true) if update

            ## Don't pass options to active_images. We don't want to filter.
            active_images({}, update).each do |_, image|
              image[:snapshots].each { |s| active[s] = snapshots[s] }
            end

            volumes({}, update).each do |_, vol|
              active[vol[:snapshot]] = snapshots[vol[:snapshot]] if snapshots.include?(vol[:snapshot])
            end
          end
        end

        def unused_snapshots(options = {}, update = false)
          return @unused_snapshots unless @unused_snapshots.nil? || update

          @unused_snapshots = {}.tap do |unused|
            (snapshots(options, update).keys - active_snapshots(options, update).keys).each do |s|
              unused[s] = snapshots[s]
            end
          end
        end

        def active_volumes(_ = {}, update = false)
          return @active_volumes unless @active_volumes.nil? || update
          @active_volumes = volumes({ 'filter' => %w(state in-use) }, update)
        end

        def unused_volumes(_ = {}, update = false)
          return @unused_volumes unless @unused_volumes.nil? || update
          @unused_volumes = volumes({ 'filter' => %w(state available) }, update)
        end
      end
    end
  end
end
