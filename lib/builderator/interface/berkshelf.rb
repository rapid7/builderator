require_relative '../config'
require_relative '../interface'
require_relative '../util'

module Builderator
  class Interface
    ##
    # Render an updated Berksfile
    ##
    class Berkshelf < Interface
      def initialize
        super

        includes Config.cookbook

        vendor Config.local.cookbook_path
        lockfile 'Berksfile.lock'
      end

      template 'template/Berksfile.erb'

      attribute :path
      attribute :vendor
      attribute :lockfile, :workspace => true

      attribute :sources, :type => :list
      attribute :metadata

      collection :depends do
        attribute :version
        attribute :git
        attribute :github
        attribute :branch
        attribute :tag
        attribute :path
      end

      ##
      # If there's a cookbook, put the Berksfile there
      ##
      def directory
        Control::Cookbook.exist? ? Config.cookbook.path : Util.workspace
      end

      def source
        directory.join('Berksfile')
      end
    end
  end
end
