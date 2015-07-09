require 'thor'
require 'thor/actions'
require_relative './berks'
require_relative '../control/packer'
require_relative '../util/shell'

module Builderator
  module Tasks
    class Packer < Thor
      include Thor::Actions
      include Util::Shell

      class_option :config, :aliases => :c, :desc => "Path to Berkshelf's config.json"
      class_option :berksfile, :aliases => :b, :desc => 'Path to the Berksfile to use'

      desc 'install [VERSION = 0.8.1]', 'Ensure that the desired version of packer is installed'
      def install(version = '0.8.1')
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
      option 'properties-file', :desc => 'Write build outputs to a properties file'
      def build(*args)
        invoke Tasks::Berks, 'vendor', [], options

        packer_output = execute("#{ Control::Packer.bin } build #{ args.join(' ') }")

        ## Try to find the ID of the new AMI
        ami_id_search = /AMI: (ami-[0-9a-f]{8})/.match(packer_output.string)
        if ami_id_search.nil?
          say_status :failure, 'Unable to find AMI ID from packer build', :red
          return
        end

        say_status :success, "Created AMI #{ ami_id_search[1] }"
        return unless options['properties-file']

        create_file options['properties-file'], '', :force => true
        append_file options['properties-file'], "image.useast1=#{ ami_id_search[1] }"
      end

      desc 'find_ami', 'Find the ID of the new AMI from packer output'
      option 'properties-file', :desc => 'Write build outputs to a properties file'
      def find_ami
        tee = Builderator::Util::Shell::BufferTee.new($stdout)
        $stdin.each { |l| tee.write(l) } # Buffer stdin

        ami_id_search = /AMI: (ami-[0-9a-f]{8})/.match(tee.string)
        if ami_id_search.nil?
          say_status :failure, 'Unable to find AMI ID from packer build', :red
          return
        end

        say_status :success, "Created AMI #{ ami_id_search[1] }"
        return unless options['properties-file']

        create_file options['properties-file'], '', :force => true
        append_file options['properties-file'], "image.useast1=#{ ami_id_search[1] }"
      end
    end
  end
end
