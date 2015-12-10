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
          return major <=> other.major unless same?(:major, other)
          return minor <=> other.minor unless same?(:minor, other)
          return patch <=> other.patch unless same?(:patch, other)

          ## Prereleases: prerelease < non-prerelease
          return compare(:is_prerelease, other) if one?(:is_prerelease, other)

          if both?(:is_prerelease, other)
            ## This is a little sketchy... We're assuming that pre-releases
            ## have a lexicological order.
            return prerelease_name <=> other.prerelease_name unless same?(:prerelease_name, other)
            return prerelease_iteration <=> other.prerelease_iteration unless same?(:prerelease_iteration, other)
          end

          ## Build number. With build number > without build number
          compare(:build, other)
        end

        private

        ## this == that
        def same?(parameter, other)
          send(parameter) == other.send(parameter)
        end

        ## this && that
        def both?(parameter, other)
          send(parameter) && other.send(parameter)
        end

        ## this ^ that (XOR)
        def one?(parameter, other)
          (send(parameter)) ^ (other.send(parameter))
        end

        ## this || that
        def either?(parameter, other)
          send(parameter) || other.send(parameter)
        end

        ## !(this || that)
        def neither?(parameter, other)
          !either?(parameter, other)
        end

        ## Compare with support for `nil` values
        def compare(parameter, other)
          a = send(parameter)
          b = other.send(parameter)

          ## NilClass, TrueClass, and FalseClass' <=> operators return nil
          return a <=> b unless a.nil? || b.nil? ||
                                a.is_a?(TrueClass) || b.is_a?(TrueClass) ||
                                a.is_a?(FalseClass) || b.is_a?(FalseClass)

          return 1 if a && !b
          return -1 if !a && b

          ## a && b || !a && !b
          0
        end
      end
    end
  end
end
