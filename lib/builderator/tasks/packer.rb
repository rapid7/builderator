require 'thor'
require 'thor/actions'
require_relative './berks'
require_relative '../control/packer'

module Builderator
  module Tasks
    class Packer < Thor
      include Thor::Actions
      class_option :config, :aliases => :c, :desc => "Path to Berkshelf's config.json"
      class_option :berksfile, :aliases => :b, :desc => 'Path to the Berksfile to use'

      desc 'install [VERSION = 0.8.0]', 'Ensure that the desired version of packer is installed'
      def install(version = '0.8.0')
        Control::Packer.use(version)

        if Control::Packer.installed?
          say_status :packer, "is already installed at version #{ version }"
          return
        end

        say_status :packer, "install version #{ version } to #{ Control::Packer.path }"
        run "wget #{ Control::Packer.url } -O packer.zip -q"
        run "unzip -d #{ Control::Packer.path } -q packer.zip"
      end

      desc 'build ARGS', 'Run a build with the installed version of packer'
      def build(*args)
        invoke Tasks::Berks, 'vendor', [], options
        run "#{ Control::Packer.bin } build #{ args.join(' ') }"
      end
    end
  end
end
