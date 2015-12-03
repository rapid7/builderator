require_relative '../config'
require_relative '../interface'
require_relative '../util'

require_relative '../control/cookbook'

module Builderator
  class Interface
    class << self
      def berkshelf
        @berkshelf ||= Berkshelf.new
      end
    end

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

      attribute :vendor
      attribute :berkshelf_config
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

      def source
        directory.join('Berksfile')
      end
    end
  end
end
