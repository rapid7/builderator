require 'bundler'
require 'childprocess'
require 'thor/actions'

require_relative '../util'

class Thor
  ##
  # Patch some Thor actions
  ##
  module Actions
    ##
    # Replace `run` with IO::popen to accept STDIN
    ##
    def run_with_input(command, input, config = {})
      return unless behavior == :invoke

      destination = relative_to_original_destination_root(destination_root, false)
      desc = "#{command} from #{destination.inspect}"

      if config[:with]
        desc = "#{File.basename(config[:with].to_s)} #{desc}"
        command = "#{config[:with]} #{command}"
      end

      say_status :run, desc, config.fetch(:verbose, true)
      return if options[:pretend]

      output = config.fetch(:stdout, STDOUT)

      IO.popen(command, 'r+') do |io|
        io.write(input)
        io.close_write

        ## Stream output
        loop do
          break if io.eof?

          output.write(io.readpartial(4096))
          output.flush
        end
      end
    end

    ##
    # Run an external command without bundler's injected environment variables
    # (e.g. keep vagrant happy in it's own little vendor full of unicorns)
    ##
    def run_without_bundler(command, config = {})
      destination = relative_to_original_destination_root(destination_root, false)
      desc = "#{command} from #{destination.inspect}"

      if config[:with]
        desc = "#{File.basename(config[:with].to_s)} #{desc}"
        command = "#{config[:with]} #{command}"
      end

      say_status :run, desc, config.fetch(:verbose, true)
      return if options[:pretend]

      output = config.fetch(:stdout, STDOUT)

      Bundler.with_clean_env do
        if config.fetch(:childprocess, false)
          process = ChildProcess.build(*command.split(' '))
          process.io.inherit!

          process.start
          process.wait
          return process.exit_code
        end

        IO.popen(command, 'r+') do |io|
          ## Stream output
          loop do
            break if io.eof?

            output.write(io.readpartial(4096))
            output.flush
          end
        end
      end
    end

    ##
    # Make `template` load from a sane path and render in the context of Config
    ##
    def template(source, destination, config = {})
      content = ERB.new(Builderator::Util.source_path(source).binread,
                        nil, '-', '@output_buffer').result(Builderator::Config.instance_eval('binding'))

      create_file Builderator::Util.relative_path(destination), content, config
    end
  end
end
