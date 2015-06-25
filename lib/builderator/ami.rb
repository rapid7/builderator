require 'thor'
require 'open-uri'

module Builderator
  class AMI < Thor
    desc 'ubuntu RELEASE [^daily|release]', 'Get AMI IDs for Ubuntu images'
    option 'region', :aliases => :r, :default => 'us-east-1'
    option 'architecture', :aliases => :a, :default => 'amd64'
    option 'root_volume', :aliases => :d, :default => 'ebs'
    option 'virtualization', :aliases => :v, :default => 'hvm'
    option 'one', :type => :boolean, :aliases => :o, :default => false
    def ubuntu(release, iteration = 'daily')
      images = manifest(release, iteration, options).map { |i| i[:ami] }
      puts (images.size == 1 || options[:one]) ? images.first : images
    end

    no_commands do
      def manifest_url(version, iteration)
        "http://cloud-images.ubuntu.com/query/#{ version }/server/#{ iteration }.current.txt"
      end

      def parse_tsv(blob)
        blob.split(/\r?\n/).map do |line|
          fields = line.split(/\t/)

          {
            :release => fields[3],
            :root_volume => fields[4],
            :architecture => fields[5],
            :region => fields[6],
            :ami => fields[7],
            :kernel => fields[8],
            :virtualization => fields[10]
          }
        end
      end

      def manifest(version, iteration, filter = {})
        images = parse_tsv(open(manifest_url(version, iteration)).read)
        return images if filter.empty?

        %w(region architecture root_volume virtualization).each do |f|
          next unless options.include?(f)
          images.select! { |i| i[f.to_sym] == options[f] }
        end

        images
      end
    end
  end
end
