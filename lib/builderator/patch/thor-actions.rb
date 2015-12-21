require 'mixlib/shellout'
require 'thor/actions'

require_relative '../util'

class Thor
  ##
  # Patch some Thor actions
  ##
  module Actions
    RUN_OPTIONS = %w(cwd domain password user group umask timeout returns
                     live_stream live_stdout live_stderr input logger log_level
                     log_tag environment env login)

    ##
    # Replace `run` with Mixlib::Shellout to accept STDIN
    ##
    def run(command, config = {})
      return unless behavior == :invoke

      destination = relative_to_original_destination_root(destination_root, false)
      desc = "#{command} from #{destination.inspect}"

      if config[:with]
        desc = "#{File.basename(config[:with].to_s)} #{desc}"
        command = "#{config[:with]} #{command}"
      end

      say_status :run, desc, config.fetch(:verbose, true)
      return if options[:pretend]

      shell_options = config.select { |k, _| RUN_OPTIONS.include?(k.to_s) }
      shell_options[:live_stdout] = STDOUT

      Mixlib::ShellOut.new(command, shell_options).run_command
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
