require_relative './version/auto'
require_relative './version/comparable'
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
      FORMAT = /(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-?(?<prerelease>(?<prerelease_name>[A-Za-z0-9]+)\.(?<prerelease_iteration>\d+))?(\+build\.)?(?<build>\d+)?$/
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
          @current ||= tags_from_path.last
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
          tags_from_path << current

          current
        end

        ##
        # Get information from SCM
        ##
        def tags_from_path(path = Dir.pwd)
          provider(path).tags
        end

        def history_from_path(path = Dir.pwd)
          provider(path).history
        end

        ## Parse a SemVer string into a Version
        def from_string(arg, options = {})
          matchdata = arg.match(FORMAT)

          new(matchdata[:major], matchdata[:minor], matchdata[:patch], matchdata[:build], options).tap do |version|
            if matchdata[:prerelease]
              version.is_prerelease = true
              version.prerelease_name = matchdata[:prerelease_name]
              version.prerelease_iteration = matchdata[:prerelease_iteration].to_i
            end
          end
        end

        private

        def provider(path)
          return Git if File.exist?(File.join(path, '.git'))

          fail 'Builderator::Control::Version: Unsupported SCM'
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
      include Comparable

      def history_from_path
        self.class.history_from_path
      end

      def tags_from_path
        self.class.tags_from_path
      end

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
        reset(:build) ## Reset the build counter

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

      def bump(type = 'auto', prerelease_name = nil)
        ## Grok commits since current for a #TYPE string
        type, prerelease_name = auto_type if type.to_s == 'auto'

        fail "Unrecognized release type #{type}" unless RELEASE_TYPES.include?(type.to_s)
        type_num = RELEASE_TYPES[type.to_s]

        ##
        # Reset lower-precendence parameters to nil/0
        ##
        reset(:build) if type_num < RELEASE_TYPES['build']

        ## Clear pre-release flags
        if type_num < RELEASE_TYPES['prerelease']
          self.is_prerelease = false
          self.prerelease_name = nil
          self.prerelease_iteration = nil
        end

        reset(:patch) if type_num < RELEASE_TYPES['patch']
        reset(:minor) if type_num < RELEASE_TYPES['minor']
        reset(:major) if type_num < RELEASE_TYPES['major']

        ## Set new version's ref
        self.ref = history_from_path.first.hash

        ##
        # Increment specified parameters
        ##
        case type.to_s
        when 'build'
          if build.nil?
            self.build = 0
          else
            self.build += 1
          end

        when 'prerelease'
          ## Start a prerelease train from a new patch version
          ## if it doesn't already exist
          self.patch += 1 unless is_prerelease
          prerelease(prerelease_name)

        when 'release'
          ## Remove pre-release parameters from the current patch
          ## (already done above ^^)

        when 'patch-prerelease'
          ## Force a new pre-release train from a new patch version
          self.patch += 1
          prerelease(prerelease_name)

        when 'patch' then self.patch += 1

        when 'minor-prerelease'
          self.minor += 1
          prerelease(prerelease_name)

        when 'minor' then self.minor += 1

        when 'major-prerelease'
          self.major += 1
          prerelease(prerelease_name)

        when 'major' then self.major += 1
        end

        self
      end

      ## Set a parameter back to `0` if currently defiend
      def reset(attribute)
        return unless respond_to?("#{attribute}=") && send(attribute).is_a?(Fixnum)
        send("#{attribute}=", 0)
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
