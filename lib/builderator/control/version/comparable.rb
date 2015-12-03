module Builderator
  module Control
    class Version
      ##
      # Sort earliest -> latest
      # (Array.last -> latest (e.g. 1.0.0), Array.first -> earliest(e.g. 0.0.1))
      ##
      module Comparable
        include ::Comparable

        def <=>(other)
          ## Simple version comparison
          return 1 if major > other.major
          return -1 if major < other.major

          return 1 if minor > other.minor
          return -1 if minor < other.minor

          return 1 if patch > other.patch
          return -1 if patch < other.patch

          ## Prereleases: prerelease < non-prerelease
          return 1 if !is_prerelease && other.is_prerelease
          return -1 if is_prerelease && !other.is_prerelease

          if is_prerelease && other.is_prerelease
            ## This is a little sketchy... We're assuming that pre-releases
            ## have a lexicological order.
            return 1 if prerelease_name > other.prerelease_name
            return -1 if prerelease_name < other.prerelease_name

            return 1 if prerelease_iteration > other.prerelease_iteration
            return -1 if prerelease_iteration < other.prerelease_iteration
          end

          ## Build number. With build number > without build number
          return 1 if !build.nil? && other.build.nil?
          return -1 if build.nil? && !other.build.nil?

          if !build.nil? && !other.build.nil?
            return 1 if build > other.build
            return -1 if build < other.build
          end

          0
        end
      end
    end
  end
end
