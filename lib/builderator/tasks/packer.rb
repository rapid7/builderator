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

      def self.exit_on_failure?
        true
      end

      class_option :debug, :type => :boolean

      desc 'configure [PROFILE=default]', 'Generate a packer configuration'
      def configure(profile = :default)
        Config.profile.use(profile)
        puts Interface.packer.render if options['debug']
      end

      desc 'build [PROFILE=default *ARGS]', 'Run a build with the installed version of packer'
      def build(profile = :default, *args)
        invoke :configure, [profile], options
        run_with_input "packer build - #{ args.join('') }", Interface.packer.render
      end
    end
  end
end
