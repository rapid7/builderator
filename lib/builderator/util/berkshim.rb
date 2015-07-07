##
# Roll up some shared logic for Berksfiles
##
require_relative './cookbook'

module Builderator
  module Util
    module Berkshim
      def shims

        ## Root cookbook sources
        metadata if ENV['BERKS_INSTALL_FROM'] == 'source'

        if ENV['BERKS_INSTALL_FROM'] == 'release'
          cookbook_spec = [].tap do |arguments|
            arguments << Util::Cookbook.metadata.name
            arguments << ENV['VERSION'] if ENV.include?('VERSION')

            arguments << {}.tap do |options|
              options[:path] = ENV['COOKBOOK_PATH'] if ENV.include?('COOKBOOK_PATH')
              options[:git] = ENV['COOKBOOK_REPO'] if ENV.include?('COOKBOOK_REPO')
              options[:github] = ENV['COOKBOOK_GITHUB'] if ENV.include?('COOKBOOK_GITHUB')
              options[:branch] = ENV['COOKBOOK_BRANCH'] if ENV.include?('COOKBOOK_BRANCH')
              options[:ref] = ENV['COOKBOOK_REF'] if ENV.include?('COOKBOOK_REF')
              options[:tag] = ENV['COOKBOOK_TAG'] if ENV.include?('COOKBOOK_TAG')
            end
          end

          cookbook(*cookbook_spec)
        end
      end
    end
  end
end
