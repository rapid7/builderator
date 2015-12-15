require 'aws-sdk'
require 'date'

require_relative '../../util'

module Builderator
  module Control
    # :nodoc:
    module Data
      def self.image(query = {})
        Image.search(query)
      end

      ##
      # Find AMI IDs to use for sources
      ##
      module Image
        ## Account IDs of public image owners
        OWNERS = {
          :self =>  'self'.freeze,
          :ubuntu => '099720109477'.freeze,
          :amazon => 'amazon'.freeze,
          :marketplace => 'aws-marketplace'.freeze
        }

        ## Pre-defined filters
        FILTERS = {
          'ubuntu-14.04-daily' => {
            'owner' => OWNERS[:ubuntu],
            'architecture' => 'x86_64',
            'root-device-type' => 'ebs',
            'virtualization-type' => 'hvm',
            'block-device-mapping.volume-type' => 'gp2',
            'name' => '*ubuntu-trusty-daily-amd64-server-201*'
          },
          'windows-server2012-r2' => {
            'owner' => OWNERS[:amazon],
            'architecture' => 'x86_64',
            'root-device-type' => 'ebs',
            'virtualization-type' => 'hvm',
            'block-device-mapping.volume-type' => 'gp2',
            'name' => 'Windows_Server-2012-R2_RTM-English-64Bit-Base*'
          },
          'windows-server2012-r2-core' => {
            'owner' => OWNERS[:amazon],
            'architecture' => 'x86_64',
            'root-device-type' => 'ebs',
            'virtualization-type' => 'hvm',
            'block-device-mapping.volume-type' => 'gp2',
            'name' => 'Windows_Server-2012-R2_RTM-English-64Bit-Core*'
          }
        }

        ## Filter fields defined in http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Builderator::Util.ec2.html#describe_images-instance_method
        PROPERTIES = %w(architecture block-device-mapping.delete-on-termination
                        block-device-mapping.device-name block-device-mapping.snapshot-id
                        block-device-mapping.volume-size block-device-mapping.volume-type
                        description hypervisor image-id image-type is-public kernel-id
                        manifest-location name owner-alias owner-id platform product-code
                        product-code.type ramdisk-id root-device-name root-device-type
                        state state-reason-code state-reason-message virtualization-type).freeze

        class << self
          def search(query = {})
            options = {}

            ## Reverse-merge a pre-defined filter into the query
            if query.include?('filter')
              query = FILTERS[query['filter']].merge(query) if FILTERS.include?(query['filter'])

              query.delete('filter')
            end

            options['image_ids'] = Util.to_array(query.delete('image_id')) if query.include?('image_id')
            options['owners'] = Util.to_array(query.delete('owner') { 'self' })

            options['filters'] = query.each_with_object([]) do |(k, v), memo|
              next if v.nil?

              ## Construct filter objects. Assume that non-enumerated keys are tags
              memo << {
                :name => PROPERTIES.include?(k.to_s) ? k.to_s : "tag:#{ k }",
                :values => Util.to_array(v)
              }
            end

            ## Don't send an empty filters array
            options.delete('filters') if options['filters'].empty?

            Util.ec2.describe_images(options)
              .each_with_object([]) { |page, images| images.push(*page.images) }
              .sort { |a, b| DateTime.iso8601(b.creation_date) <=> DateTime.iso8601(a.creation_date) }
          end
        end
      end
    end
  end
end
