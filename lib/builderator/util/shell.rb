require 'stringio'

module Builderator
  module Util
    ##
    # Extend the functionality of Thor::Actions::run
    ##
    module Shell
      def execute(command, config = {})
        return unless behavior == :invoke

        destination = relative_to_original_destination_root(destination_root, false)
        desc = "#{command} from #{destination.inspect}"

        if config[:with]
          desc = "#{File.basename(config[:with].to_s)} #{desc}"
          command = "#{config[:with]} #{command}"
        end

        say_status :run, desc, config.fetch(:verbose, true)
        BufferTee.new($stdout).tap do |t|
          IO.popen(command, :err => [:child, :out]).each { |l| t.write(l) }
        end unless options[:pretend]
      end

      ##
      # Buffer an IO stream and forward to another IO instance
      ##
      class BufferTee < StringIO
        attr_reader :output

        def initialize(out, *args)
          super(*args)
          @output = out
        end

        def write(data)
          super(data)
          output.write(data)
        end
      end
    end
  end
end
