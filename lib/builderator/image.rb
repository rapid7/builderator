require 'thor'
require_relative './util'

module Builderator
  ##
  # Image operations
  ##
  class Image

    attr_reader :source_region, :dest_region, :source_image_id, :image_name, :description
    attr_reader :ec2_client, :thor

    AWS_ERRORS = [Aws::EC2::Errors::ServiceError].freeze

    def initialize(source_region:, dest_region:, source_image_id:, image_name:, description:)
      @source_region = source_region
      @dest_region = dest_region
      @source_image_id = source_image_id
      @image_name = image_name
      @description = description
      @ec2_client = Util.ec2(dest_region)
      @thor = Thor::Shell::Basic.new
    end

    def copy
      thor.say_status :copy, "image #{image_name} (#{source_image_id}) from #{source_region} to #{dest_region}"
      copy_image
    end



    private

    def copy_params
      {
        source_region: source_region,
        source_image_id: source_image_id,
        name: image_name,
        description: description
      }
    end

    def copy_image
      Retryable.retryable(sleep: ->(n) { 4**n }, tries: 4, on: AWS_ERRORS) do |retries, _|
        say_status :error, 'Error copying image', :red if retries.positive?
        ec2_client.copy_image(copy_params)
      end
    end
  end
end
