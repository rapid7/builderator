require 'aws-sdk'
require 'date'

require_relative '../util'

module Builderator
  module Control
    ##
    # Find AMI IDs to use for sources
    ##
    module AMI
      ## Account IDs of public image owners
      module Owners
        SELF = 'self'.freeze
        UBUNTU = '099720109477'.freeze
      end

      ## Filter fields defined in http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#describe_images-instance_method
      FILTERS = %w(architecture block-device-mapping.delete-on-termination
                   block-device-mapping.device-name block-device-mapping.snapshot-id
                   block-device-mapping.volume-size block-device-mapping.volume-type
                   description hypervisor image-id image-type is-public kernel-id
                   manifest-location name owner-alias owner-id platform product-code
                   product-code.type ramdisk-id root-device-name root-device-type
                   state state-reason-code state-reason-message virtualization-type).freeze

      class << self
        def region(arg = nil)
          return @region || 'us-east-1' if arg.nil?
          @region = arg
        end

        def client
          @client ||= Aws::EC2::Client.new(:region => region)
        end

        def search(filters = {})
          [].tap do |images|
            client.describe_images(search_options(filters)).each { |page| images.push(*page.images) }
          end
        end

        def latest(filters)
          search(filters).sort do |a, b|
            DateTime.iso8601(b.creation_date) <=> DateTime.iso8601(a.creation_date)
          end.first
        end

        private

        def search_options(filters)
          {}.tap do |options|
            options[:image_ids] = Util.to_array(filters.delete(:image_id)) if filters.include?(:image_id)
            options[:owners] = Util.to_array(filters.delete(:owner) { 'self' })

            rfilters = [].tap do |f|
              filters.each do |k, v|
                next if v.nil?

                f << {
                  :name => FILTERS.include?(k.to_s) ? k : "tag:#{ k }",
                  :values => Util.to_array(v)
                }
              end
            end

            options[:filters] = rfilters unless rfilters.empty?
          end
        end
      end
    end
  end
end
