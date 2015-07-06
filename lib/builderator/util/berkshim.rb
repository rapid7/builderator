##
# Roll up some shared logic for Berksfiles
##
module Builderator
  module Util
    module Berkshim
      def shims

        ## Root cookbook sources
        metadata if ENV['BERKS_INSTALL_FROM'] == 'source'
        cookbook(*([].tap do |arguments|
          arguments << ENV['COOKBOOK']
          arguments << ENV['VERSION'] unless ENV['VERSION'] == 'LATEST'
          arguments << {}.tap do |options|
            options[:path] = ENV['COOKBOOK_PATH'] if ENV.include?('COOKBOOK_PATH')
            options[:git] = ENV['COOKBOOK_REPO'] if ENV.include?('COOKBOOK_REPO')
            options[:github] = ENV['COOKBOOK_GITHUB'] if ENV.include?('COOKBOOK_GITHUB')
            options[:branch] = ENV['COOKBOOK_BRANCH'] if ENV.include?('COOKBOOK_BRANCH')
            options[:ref] = ENV['COOKBOOK_REF'] if ENV.include?('COOKBOOK_REF')
            options[:tag] = ENV['COOKBOOK_TAG'] if ENV.include?('COOKBOOK_TAG')
          end
        end)) if ENV['BERKS_INSTALL_FROM'] == 'release'
      end
    end
  end
end
