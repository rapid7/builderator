module Builderator
  module Control
    class Version
      ##
      # Generic SCM interface
      ##
      module SCM
        ## Fetch and cache history for the current HEAD/TIP
        def history
          @history ||= _history.map { |commit| Commit.new(commit) }
        end

        ## Find all tags in the branch's history
        def tags
          @tags ||= _tags
                    .map { |tag, ref| Version.from_string(tag, :ref => ref) }
                    .compact
                    .sort
        end

        ##
        # OVERRIDE: Return true if this provider will work for `path`
        ##
        def supported?
          fail 'Method `supported?` must be implemented in SCM providers!'
        end

        ##
        # OVERRIDE: Return an array of hashes with keys
        # - id -> SCM commit identity
        # - message -> SCM commit message
        # - tags -> nil or an array of strings
        ##
        def _history
          fail 'Method `_history` must be implemented in SCM providers!'
        end

        ##
        # OVERRIDE: Return an array of [tag, commit-id] tuples
        ##
        def _tags
          history.reject { |commit| commit.tags.empty? }
            .map { |commit| commit.tags.map { |tag| [tag, commit.id] } }
            .each_with_object([]) { |commit, tags| tags.push(*commit) }
        end

        class << self
          def history
            provider.history
          end

          def tags
            provider.tags
          end

          def register(klass)
            fail 'Provider module must extend '\
                 'Builderator::Control::Version::SCM' unless
                 klass.singleton_class.include?(SCM)

            ## Make newer providers override those with the same capability
            providers.unshift(klass)
          end

          def providers
            @providers ||= []
          end

          ## Find a version provider for this build
          def provider
            providers.find(&:supported?).tap do |found|
              fail 'Builderator::Control::Version: '\
                   'Unsupported SCM' if found.nil?
            end
          end
        end

        ## An SCM commit entity
        class Commit
          attr_reader :id
          attr_reader :message
          attr_reader :tags

          def initialize(match)
            @id = match[:id]
            @message = match[:message]
            @tags = match.fetch(:tags, [])
          end
        end
      end
    end
  end
end
