require 'aws-sdk-ecr'
require 'date'

require_relative '../../util'

module Builderator
  module Control
    # :nodoc:
    module Data
      # Lookup ECR repository info
      #
      # NB. We want to embed the login_server info into the returned repo data for
      # ease of use. Thus, instead of an AWS struct-type, we get a hash with the
      # injected value.
      def self.repository(query = {})
        ECR.search(query).map do |repo|
          repo.to_h.tap { |r| r[:login_server] = "https://#{repo.repository_uri.sub(repo.repository_name, '')}" }
          end
        end
      end

      ##
      # Find ECR repositories for sources
      ##
      module ECR
        class << self
          def search(query = {})
            options = {}

            options['repository_names'] = Util.to_array(query.delete('name')) if query.include?('name')
            options['registry_id'] = query.delete('owner') if query.include?('owner')

            Util.ecr.describe_repositories(options)
              .each_with_object([]) { |page, repositories| repositories.push(*page.repositories) }
              .sort { |a, b| a.repository_name <=> b.repository_name }
          end
        end
      end
    end
end
