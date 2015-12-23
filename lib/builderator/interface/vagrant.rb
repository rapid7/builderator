require_relative '../interface'

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
      command 'vagrant'
      template 'template/Vagrantfile.erb'

      def command
        c = ''
        c << 'ulimit -n 1024; ' if bundled?
        c << 'VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true ' if bundled?
        c << which
      end

      def source
        directory.join('Vagrantfile')
      end
    end
  end
end
