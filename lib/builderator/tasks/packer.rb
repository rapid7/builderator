require 'thor'

require_relative '../interface/packer'
require_relative '../patch/thor-actions'

module Builderator
  module Tasks
    ##
    # Wrap Packer commands
    ##
    class Packer < Thor
      include Thor::Actions

      attr_reader :config, :command

      def self.exit_on_failure?
        true
      end

      desc 'build [PROFILE=default *ARGS]', 'Run a build with the installed version of packer'
      def build(profile = :default, *args)
        @config ||= Interface.packer(profile)

        puts Interface.packer(profile).render if options['debug']
        run_with_input "packer build - #{ args.join('') }", config.render
      end
    end
  end
end
