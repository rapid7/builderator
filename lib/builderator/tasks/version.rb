require 'thor'

require_relative '../patch/thor-actions'
require_relative '../control/version'
require_relative '../util'

module Builderator
  module Tasks
    class Version < Thor
      include Thor::Actions

      def self.exit_on_failure?
        true
      end

      desc 'current', 'Print the current version and write it to file'
      def current
        unless Config.autoversion.search_tags
          say_status :disabled, 'Automatically detecting version informantion '\
                                'from SCM tags is disabled', :white
          return
        end

        say_status :version, "#{Control::Version.current} (#{Control::Version.current.ref})"
        Control::Version.write
        Control::Version.set_config_version
      end

      desc 'bump TYPE [PRERELEASE_NAME]', 'Increment the package version, optionally with a named prerelease'
      def bump(type = :auto, prerelease_name = nil)
        unless Config.autoversion.search_tags
          say_status :disabled, 'Automatically detecting version informantion '\
                                'from SCM tags is disabled', :white
          return
        end

        say_status :bump, "by #{type} version"
        say_status :version, "#{Control::Version.bump(type, prerelease_name)} (#{Control::Version.current.ref})"

        Util.relative_path('VERSION').write(Control::Version.current.to_s)

        unless Config.autoversion.create_tags
          say_status :disabled, 'Tag creation is disabled for this build. Not '\
                                'creating new SCM tags!', :white
          return
        end

        run "git tag #{Control::Version.current}"
        run 'git push --tags'
      end
    end
  end
end
