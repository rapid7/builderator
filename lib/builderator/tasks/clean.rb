require 'thor'
require_relative '../model'

module Builderator
  module Tasks
    class Clean < Thor
      class_option :commit, :type => :boolean, :default => false, :desc => 'Execute cleanup'
      class_option :filter,
                   :type => :array,
                   :desc => 'Key/value pairs to filter resources (--filter name foo owner_id 123456789)'

      desc 'configs', 'Delete unused launch configurations'
      def configs
        Model.launch_configs.unused.each do |l, _|
          say_status :remove, "Launch Configuration #{ l }", :red
          Model.launch_configs.resources.delete(l)
        end
      end

      desc 'images', 'Deregister unused images'
      option 'group-by',
             :type => :array,
             :desc => 'Tags/properties to group images by for pruning'
      option 'sort-by',
             :type => :string,
             :default => 'creation_date',
             :desc => 'Tag/property to sort grouped images on'
      option :keep,
             :type => :numeric,
             :default => 5,
             :desc => 'Number of images in each group to keep'
      def images
        options['filters'] = Hash[*options['filter']]
        Model.images.unused(options).each do |i, image|
          say_status :remove, "Image #{ i } (#{ image[:properties]['name'] })", :red
          Model.images.resources.delete(i)
        end
      end

      desc 'snapshots', 'Delete unused snapshots'
      def snapshots
        Model.snapshots.unused.each do |s, _|
          say_status :remove, "Snapshot #{ s }", :red
          Model.snapshots.resources.delete(s)
        end
      end

      desc 'volumes', 'Delete unused volumes'
      def volumes
        Model.volumes.unused.each do |v, _|
          say_status :remove, "Volume #{ v }", :red
          Model.volumes.resources.delete(v)
        end
      end

      desc 'all', 'Clean volumes, launch configs, images, and snapshots in order'
      option 'group-by',
             :type => :array,
             :desc => 'Tags/properties to group images by for pruning'
      option 'sort-by',
             :type => :string,
             :default => 'creation_date',
             :desc => 'Tag/property to sort grouped images on'
      option :keep,
             :type => :numeric,
             :default => 5,
             :desc => 'Number of images in each group to keep'
      def all
        invoke :volumes
        invoke :configs
        invoke :images
        invoke :snapshots
      end
    end
  end
end
