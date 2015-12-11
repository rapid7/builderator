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

      desc 'build ARGS', 'Run a build with the installed version of packer'
      def build(profile = :default, *args)
        @config ||= Interface.packer(profile)

        run "packer build - #{ args.join('') }", :input => config.render
      end
    end
  end
end
