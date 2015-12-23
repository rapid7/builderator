require_relative '../interface'
require_relative '../util'

module Builderator
  # :nodoc:
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
      from_gem 'berkshelf'
      command 'berks'
      template 'template/Berksfile.erb'

      def vendor
        Config.local.cookbook_path
      end

      def lockfile
        Util.workspace('Berksfile.lock')
      end

      def berkshelf_config
        Config.cookbook.berkshelf_config
      end

      def source
        directory.join('Berksfile')
      end
    end
  end
end
