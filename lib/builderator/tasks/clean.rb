require 'thor'
require_relative '../control/clean'

module Builderator
  module Tasks
    class Clean < Thor
      class_option :region,
                   :type => :string,
                   :default => 'us-east-1',
                   :aliases => :r,
                   :desc => 'AWS Region in which to perform tasks'
      class_option :commit,
                   :type => :boolean,
                   :default => false,
                   :desc => 'Perform mutating API calls to cleanup resources'
      class_option :filter,
                   :type => :array,
                   :aliases => :f,
                   :desc => 'Key/value pairs to filter resources (--filter name foo owner_id 123456789)'
      class_option :limit,
                   :type => :boolean,
                   :default => true,
                   :desc => 'By default, limit the number of resources to remove'

      def initialize(*_)
        super

        ## Convert array of filter key-values to a hash
        options['filters'] = Hash[*options['filter']] if options['filter'].is_a?(Array)

        Control::Clean.options(options)
      end

      desc 'configs', 'Delete unused launch configurations'
      def configs
        Control::Clean.configs!(&method(:say_status))
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
        Control::Clean.images!(&method(:say_status))
      end

      desc 'snapshots', 'Delete unused snapshots'
      def snapshots
        Control::Clean.snapshots!(&method(:say_status))
      end

      desc 'volumes', 'Delete unused volumes'
      def volumes
        Control::Clean.volumes!(&method(:say_status))
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
        invoke :volumes, [], options
        invoke :configs, [], options
        invoke :images, [], options
        invoke :snapshots, [], options

        return if Control::Clean.exceptions.empty?

        say_status :fail, 'Not all tasks completed successfully. The following '\
          'exceptions occured:', :red
        Control::Clean.exceptions.each do |e|
          say_status(*e.status)
        end
      end
    end
  end
end
