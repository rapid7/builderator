require_relative './version/auto'
require_relative './version/bump'
require_relative './version/comparable'
require_relative './version/scm'
require_relative './version/git'

module Builderator
  module Control
    ##
    # Version management tools
    #
    # Initial version boosted shamelessly from
    # https://github.com/RiotGamesMinions/thor-scmversion
    ##
    class Version
      FORMAT = /(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?<prerelease>-(?<prerelease_name>[A-Za-z0-9]+)\.(?<prerelease_iteration>\d+))?(?:\+build\.(?<build>\d+))?$/
      DEFAULT_PRERELEASE_NAME = 'alpha'.freeze

      ## Order of precedence for release types
      RELEASE_TYPES = {
        'major' => 0,
        'major-prerelease' => 5,
        'minor' => 10,
        'minor-prerelease' => 15,
        'patch' => 20,
        'patch-prerelease' => 25,
        'release' => 30,
        'prerelease' => 35,
        'build' => 40
      }

      class << self
        def current
          @current ||= SCM.tags.last

          if @current.nil? && Util.relative_path('VERSION').exist?
            @current ||= Version.from_string(Util.relative_path('VERSION').read)
          end

          if @current.nil?
            fail 'No current version found! Create a VERSION file or set a version tag in your SCM.'
          end

          @current
        end

        def set_config_version
          Config.defaults.version = current.to_s
          Config.recompile
        end

        def write
          current.write
        end

        ##
        # Alias `bump` to the current version
        ##
        def bump(type = nil, prerelease_name = nil)
          @current = current.clone

          current.bump(type, prerelease_name)
          SCM.tags << current

          current
        end

        ## Parse a SemVer string into a Version
        def from_string(arg, options = {})
          matchdata = arg.match(FORMAT)
          return nil if matchdata.nil?

          new(matchdata[:major], matchdata[:minor], matchdata[:patch], matchdata[:build], options).tap do |version|
            version.is_prerelease = !matchdata[:prerelease].nil?
            if version.is_prerelease
              version.prerelease_name = matchdata[:prerelease_name]
              version.prerelease_iteration = matchdata[:prerelease_iteration].to_i
            end
          end
        end
      end

      def initialize(major, minor, patch, build = nil, **options)
        @major = major.to_i
        @minor = minor.to_i
        @patch = patch.to_i
        @build = build.to_i unless build.nil?

        @ref = options[:ref]
      end

      include Auto
      include Bump
      include Comparable

      attr_accessor :ref

      attr_accessor :major
      attr_accessor :minor
      attr_accessor :patch

      attr_accessor :is_prerelease
      attr_accessor :prerelease_name
      attr_accessor :prerelease_iteration

      attr_accessor :build

      ## Create or bump a new prerelease train
      def prerelease(name = nil)
        self.build = nil ## Reset the build counter

        ## Increment current prerelease train
        if is_prerelease && (name.nil? || name == prerelease_name)
          self.prerelease_iteration += 1
          return self
        end

        ## New prerelease train
        self.is_prerelease = true
        self.prerelease_name = name.nil? ? DEFAULT_PRERELEASE_NAME : name
        self.prerelease_iteration = 0

        self
      end

      def write
        Util.relative_path('VERSION').write(to_s)
      end

      def to_s
        string = [major, minor, patch].join('.')
        string << "-#{prerelease_name}.#{prerelease_iteration}" if is_prerelease
        string << "+build.#{build}" unless build.nil?
        string
      end
    end
  end
end
