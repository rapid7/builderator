require_relative '../config'
require_relative '../interface'
require_relative '../util'

module Builderator
  # :nodoc:
  class Interface
    class << self
      def vagrant
        @vagrant ||= Vagrant.new
      end
    end

    ##
    # Render a temporary Vagrantfile
    ##
    class Vagrant < Interface
      template 'template/Vagrantfile.erb'

      def source
        directory.join('Vagrantfile')
      end
    end
  end
end
