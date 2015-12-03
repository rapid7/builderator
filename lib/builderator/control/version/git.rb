module Builderator
  module Control
    class Version
      ##
      # Read and update Git tags
      ##
      module Git
        class << self
          COMMIT_FORMAT = /^(?<hash>[a-f0-9]+)(?:\s+\((?<tags>.+?)\))?\s+(?<message>.+)$/
          TAG_FORMAT = /tag: ([a-zA-Z0-9\.\-\+\/_]+)/

          ## Fetch and cache history for the current branch
          def history
            @history ||= `git log --pretty='format:%H %d %s' HEAD`.chomp
                         .split("\n")
                         .map { |commit| Commit.new(commit) }
          end

          ## Find all tags in the branch's history
          def tags
            @tags ||= history
                      .reject { |commit| commit.tags.nil? }
                      .map do |commit|
                        commit.tags.map { |tag| Version.from_string(tag, :ref => commit.hash) }
                      end.flatten.sort
          end

          ## Parse git-log outputs
          class Commit
            attr_reader :hash
            attr_reader :message
            attr_reader :tags

            def initialize(string)
              match = string.match(COMMIT_FORMAT)

              @hash = match[:hash]
              @message = match[:message]
              @tags = match[:tags].scan(TAG_FORMAT).flatten unless match[:tags].nil?
            end
          end
        end
      end
    end
  end
end
