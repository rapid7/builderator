require 'thor'
require_relative '../control/asg'
require_relative '../control/ec2'

module Builderator
  module Tasks
    class Clean < Thor
      class_option :commit, :type => :boolean, :default => false, :desc => 'Execute cleanup'
      class_option :filter,
                   :type => :array,
                   :desc => 'Key/value pairs to filter resources (--filter name foo owner_id 123456789)'

      desc 'configs', 'Delete unused launch configurations'
      def configs
        Control::ASG.unused_launch_configs.each do |l, _|
          say_status :remove, "Launch Configuration #{ l }", :red
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
        Control::EC2.unused_images(options).each do |i, image|
          say_status :remove, "Image #{ i } (#{ image[:properties]['name'] })", :red
        end
      end

      desc 'snapshots', 'Delete unused snapshots'
      def snapshots
        Control::EC2.unused_snapshots.each do |i, _|
          say_status :remove, "Snapshot #{ i }", :red
        end
      end

      desc 'volumes', 'Delete unused volumes'
      def volumes
        Control::EC2.unused_volumes.each do |i, _|
          say_status :remove, "Volume #{ i }", :red
        end
      end
    end
  end
end
