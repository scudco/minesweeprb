# frozen_string_literal: true

require 'pastel'
require 'tty-reader'
require 'tty-screen'

require_relative '../command'
require_relative '../gameboard'

module Minesweeprb
  module Commands
    class Play < Minesweeprb::Command
      def initialize(options)
        @options = options
        @pastel = Pastel.new
      end

      def execute(input: $stdin, output: $stdout)
        size = prompt.select('Size:', Gameboard::SIZES.keys, cycle: true)
        output.print cursor.up(1)
        output.print cursor.clear_screen_down
        output.puts

        gameboard = Minesweeprb::Gameboard.new(size)
        width = TTY::Screen.width

        gameboard.to_s.each_line do |line|
          padding = (width - line.length) / 2
          output.print(' ' * padding)
          output.print line
        end

        output.puts

        reader
          .on(:keyescape) { exit }
          .on(:keyalpha) { |event| exit if event.value.downcase == 'q' }
          .on(:keypress) do |event|
            case event.key.name
            when :up, :down, :left, :right then move(event.key.name)
            end
          end

        print cursor.up(gameboard.height + 2)

        loop { reader.read_keypress }
      end

      def move(direction)
        print case direction
              when :up then cursor.up
              when :down then cursor.down
              when :left then cursor.backward
              when :right then cursor.forward
              end
      end

      def reader
        @reader ||= TTY::Reader.new
      end
    end
  end
end
