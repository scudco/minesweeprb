# frozen_string_literal: true

require 'thor'

module Minesweeprb
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    default_command 'play'

    desc 'version', 'minesweeprb version'
    def version
      require_relative 'version'
      puts "v#{Minesweeprb::VERSION}"
    end
    map %w[--version -v] => :version

    desc 'play', 'Play Minesweeper'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def play(*)
      if options[:help]
        invoke :help, ['play']
      else
        require_relative 'commands/play'
        Minesweeprb::Commands::Play.new(options).execute
      end
    end
  end
end
