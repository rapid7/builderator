module Builderator
  module Control
    class Version
      ##
      # Search through commits since current version for #TYPE tags
      #
      # Included in Version
      ##
      module Auto
        DEFAULT_TYPE = 'patch'.freeze
        MESSAGE_KEYWORDS = /#(?<type>build|prerelease|release|patch\-prerelease|patch|minor\-prerelease|minor|major\-prerelease|major)(?:=(?<prerelease>[a-zA-Z0-9\-_]+))?/

        def auto_type
          fail 'Version-bump type `auto` is unsuppoeted for this SCM. Version does not'\
               ' have a valid `ref` value' if ref.nil?

          ## Get commits since self.ref (e.g. commits since this tag)
          history_since_current = SCM.history.take_while do |commit|
            commit.id != ref
          end

          ## Search for the highest-precedence #TAG in those commit messages
          ## Search from oldest-to-newest. Newer #TAGs of equal precedence win
          result = history_since_current.reverse.reduce(nil) do |highest, commit|
            ## Not going to bother parsing multiple matches. If you're
            ## putting more than one #TYPE in your commit message, you
            ## deserve what you get...
            found_type = commit.message.scan(MESSAGE_KEYWORDS).first

            ## No #TYPE in message
            next highest if found_type.nil?

            ## First match
            next found_type if highest.nil?

            ## Retrun higher precedence release type
            RELEASE_TYPES[found_type.first.to_s] <= RELEASE_TYPES[highest.first.to_s] ? found_type : highest
          end

          return ['prerelease', nil] if result.nil? && is_prerelease
          return [DEFAULT_TYPE, nil] if result.nil?

          result
        end
      end
    end
  end
end
