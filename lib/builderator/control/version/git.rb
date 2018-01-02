require_relative './scm'
require_relative '../../util'

module Builderator
  module Control
    # :nodoc:
    class Version
      ##
      # SCM implementation for Git
      ##
      module Git
        extend SCM

        COMMIT_FORMAT = /^(?<hash>[a-f0-9]+)(?:\s+\((?<tags>.+?)\))?\s+(?<message>.+)$/
        TAG_FORMAT = %r{tag: ([a-zA-Z0-9\.\-\+/_]+)}

        ## Is there a .git repo in the project root?
        def self.supported?
          return true if ENV['GIT_DIR'] && File.exist?(ENV['GIT_DIR'])

          Util.relative_path('.git').exist?
        end

        def self._history
          `git log --pretty='format:%H %d %s' HEAD`.chomp
            .split("\n")
            .map { |string| string.match(COMMIT_FORMAT) }
            .reject(&:nil?)
            .map do |commit|
              {
                :id => commit[:hash],
                :message => commit[:message]
              }.tap do |c|
                tag_match = commit[:tags].scan(TAG_FORMAT)
                            .flatten
                            .reject(&:nil?) unless commit[:tags].nil?

                c[:tags] = tag_match unless tag_match.nil? || tag_match.empty?
              end
            end
        end
      end

      SCM.register(Git)
    end
  end
end
