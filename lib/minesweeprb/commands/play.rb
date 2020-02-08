# frozen_string_literal: true

require 'tty-reader'
require 'tty-screen'

require_relative '../command'
require_relative '../gameboard'

module Minesweeprb
  module Commands
    class Play < Minesweeprb::Command
      def initialize(options)
        @options = options
      end

      def execute(input: $stdin, output: $stdout)
        size = prompt_size(output)
        gameboard = Gameboard.new(size)

        begin
          gameboard.draw
        ensure
          gameboard.clear
        end
      end

      private

      def prompt_size(output)
        sizes = Game::SIZES.map.with_index do |size, index|
          too_big = size[:height] * 2 > TTY::Screen.height || size[:width] * 2 > TTY::Screen.width
          disabled = '(screen too small)' if too_big
          size.merge(
            value: index,
            disabled: disabled
          )
        end

        size = prompt(interrupt: -> { exit 1 }).select('Size:', sizes, cycle: true)
        output.print cursor.hide
        output.print cursor.up(1)
        output.print cursor.clear_screen_down
        output.puts
        size
      end
    end
  end
end
