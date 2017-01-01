# encoding: utf-8

require 'tty-prompt'
require 'tty-which'
require 'shellwords'

module TTY
  # A class responsible for launching an editor
  #
  # @api private
  class Editor
    # Raised when command cannot be invoked
    class CommandInvocationError < RuntimeError; end

    # Raised when editor cannot be found
    class EditorNotFoundError < RuntimeError; end


    # Check if editor exists
    #
    # @return [Boolean]
    #
    # @api private
    def self.exist?(cmd)
      TTY::Which.exist?(cmd)
    end

    # List possible executable for editor command
    #
    # @return [Array[String]]
    #
    # @api private
    def self.executables
      [ENV['VISUAL'], ENV['EDITOR'],
       'vim', 'vi', 'emacs', 'nano', 'nano-tiny', 'pico', 'mate -w'].compact
    end

    # Find available command
    #
    # @param [Array[String]] commands
    #
    # @return [Array[String]]
    #
    # @api public
    def self.available(*commands)
      commands = commands.empty? ? executables : commands
      commands.uniq.select(&method(:exist?))
    end


    # Open file in system editor
    #
    # @param [String] file
    #   the name of the file
    #
    #
    # @return [Object]
    #
    # @api public
    def self.open(*args)
      editor = new(*args)

      yield(editor) if block_given?

      editor.run
    end

    # Initialize an Editor
    #
    # @param [String] file
    #
    # @api public
    def initialize(filename, **options)
      @env      = options.fetch(:env) { { } }
      @command  = options[:command]
      @filename = filename
    end

    # Finds command using a configured command(s) or detected shell commands.
    #
    # @param [Array[String]] commands
    #
    # @raise [TTY::CommandInvocationError]
    #
    # @return [String]
    #
    # @api public
    def command(*commands)
      if @command && commands.empty?
        @command
      else
        execs = self.class.available(*commands)
        if execs.empty?
          raise EditorNotFoundError,
                'Could not find editor to use. Please specify $VISUAL or $EDITOR'
        else
          exec = if execs.size > 1
                   prompt = TTY::Prompt.new
                   prompt.enum_select('Select an editor?', execs)
                 else
                   execs[0]
                 end
          @command = TTY::Which.which(exec)
        end
      end
    end

    # Check if Windowz
    #
    # @return [Boolean]
    #
    # @api public
    def windows?
      File::ALT_SEPARATOR == "\\"
    end

    # Escape file path
    #
    # @api private
    def escape_file
      if windows?
        @filename.gsub(/\//, '\\')
      else
        Shellwords.shellescape(@filename)
      end
    end

    # Build command path to invoke
    #
    # @return [String]
    #
    # @api private
    def command_path
      "#{command} #{escape_file}"
    end

    # Inovke editor command in a shell
    #
    # @raise [TTY::CommandInvocationError]
    #
    # @api private
    def run
      status = system(*Shellwords.split(command_path))
      return status if status
      fail CommandInvocationError,
           "`#{command_path}` failed with status: #{$? ? $?.exitstatus : nil}"
    end
  end # Editor
end # TTY
