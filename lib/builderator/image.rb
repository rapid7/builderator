# frozen_string_literal: true

require 'thor'
require_relative './util'
require_relative '../../foo'
require 'retryable'

module Builderator
  ##
  # Image operations
  ##
  class Image
    # :nodoc:
    class ImageCopyError < StandardError
      def new(_)
        'Image has failed to copy to the remote region'
      end
    end

    class TooManyTriesError < StandardError; end # TODO: add the message/excpetion inline here
    class RetryableImageCopyError < StandardError; end

    include AsyncSleep

    attr_reader :source_region, :dest_region, :source_image_id, :image_name, :description
    attr_reader :ec2_client, :thor

    attr_accessor :image

    AWS_ERRORS = [Aws::EC2::Errors::ServiceError].freeze

    def initialize(source_region:, dest_region:, source_image_id:, image_name:, description:)
      @source_region = source_region
      @dest_region = dest_region
      @source_image_id = source_image_id
      @image_name = image_name
      @description = description
      @ec2_client = Util.ec2(dest_region)
      @thor = Thor::Shell::Basic.new
      @image = nil
      @failed_state = 0
    end

    def copy
      thor.say_status :copy, "image #{image_name} (#{source_image_id}) from #{source_region} to #{dest_region}"
      copy_image
      wait
      # tag
      # share
    end

    def wait
      thor.say_status :wait, "for #{source_image_id} (#{image_name}) to be available in #{dest_region}", :yellow
      # image = find_image
      # FIXME: !!!!!!!
      retry_copy = check_failed_state if waiting?
      should_retry = should_retry_copy? if waiting?
      return copy if should_retry

      thor.say_status :image, "#{image.image_id} (#{image.name}) is #{state} in #{region}", status_color
      sleep(10) if waiting
    end

    def available?
      @image = find_image if image.nil?
      return false if state.nil?
      state == 'available'
    end

    private

    def waiting?
      !available?
    end

    def copy_image
      return if available?
      params = {
        source_region: source_region,
        source_image_id: source_image_id,
        name: image_name,
        description: description
      }

      ::Retryable.retryable(sleep: ->(n) { 4**n }, tries: 4, on: AWS_ERRORS) do |retries, _|
        thor.say_status :error, 'Error copying image', :red if retries >= 3
        raise TooManyTriesError, "Too retried exception too many times. #{exception}" if retries >= 3
        ec2_client.copy_image(params)
      end
    end

    def find_image
      filters = [{
        :name => 'name',
        :values => [image_name]
      }]

      image = nil
      ::Retryable.retryable(sleep: ->(n) { 4**n }, tries: 4, on: AWS_ERRORS) do |retries, _|
        thor.say_status :error, 'Error finding image', :red if retries >= 3
        raise TooManyTriesError, "Too retried exception too many times. #{exception}" if retries >= 3
        image = ec2_client.describe_images(:filters => filters).images.first
      end
      image
    end

    def state
      return if image.nil?
      image.state
    end

    def status_color
      case state
      when 'pending', 'unknown' then :yellow
      when 'available' then :green
      else :red
      end
    end

    def check_failed_state
      return unless state == 'failed'
      @failed_state += 1
      raise ImageCopyError, 'Image has failed to copy to the remote region' if @failed_state > 5
      p @failed_state
      # raise RetryableImageCopyError
      copy
      @failed_state
    # rescue RetryableImageCopyError
    #   copy
    # else
    end
  end
end
