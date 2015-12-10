module Builderator
  module Control
    class Version
      ##
      # Increment version's parameters by specified steps
      #
      # Included in Version
      ##
      module Bump
        def bump(type = 'auto', prerelease_name = nil) # rubocop:disable Metrics/PerceivedComplexity
          ## Grok commits since current for a #TYPE string
          type, prerelease_name = auto_type if type.to_s == 'auto'

          fail "Unrecognized release type #{type}" unless RELEASE_TYPES.include?(type.to_s)
          type_num = RELEASE_TYPES[type.to_s]

          ##
          # Reset lower-precendence parameters to nil/0
          ##
          self.build = nil if type_num < RELEASE_TYPES['build']

          ## Clear pre-release flags
          if type_num < RELEASE_TYPES['prerelease']
            self.is_prerelease = false
            self.prerelease_name = nil
            self.prerelease_iteration = nil
          end

          self.patch = 0 if type_num < RELEASE_TYPES['patch']
          self.minor = 0 if type_num < RELEASE_TYPES['minor']
          self.major = 0 if type_num < RELEASE_TYPES['major']

          ## Set new version's ref
          self.ref = SCM.history.first.id

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
      end
    end
  end
end
