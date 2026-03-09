# frozen_string_literal: true

require 'optparse'

module Minesweeprb
  class CLI
    Error = Class.new(StandardError)

    def self.start(argv = ARGV)
      options = {}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: minesweeprb [options]"

        opts.on("-v", "--version", "Print version") do
          require_relative 'version'
          puts "v#{Minesweeprb::VERSION}"
          exit
        end

        opts.on("-h", "--help", "Show this help") do
          puts opts
          exit
        end
      end

      parser.parse!(argv)

      require_relative 'commands/play'
      Commands::Play.new(options).execute
    end
  end
end
