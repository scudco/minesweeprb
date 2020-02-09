# frozen_string_literal: true

require 'tty-reader'
require 'tty-screen'

require_relative '../command'
require_relative '../gameboard'
require_relative '../game_template'

module Minesweeprb
  module Commands
    class Play < Minesweeprb::Command
      SIZES = [
        # [ label, width, height, # of mines ]
        ['Tiny',    5,  5,  3],
        ['Small',   9,  9, 10],
        ['Medium', 13, 13, 15],
        ['Large',  17, 17, 20],
        ['Huge',   21, 21, 25],
      ].map { |options| GameTemplate.new(*options) }.freeze

      def initialize(options)
        @options = options
      end

      def execute(input: $stdin, output: $stdout)
        template = prompt_size(output)
        template = prompt_custom(output) if template == :custom

        game = Game.new(**template.to_h)
        gameboard = Gameboard.new(game)
        begin
          gameboard.draw
        ensure
          gameboard.clear
        end
      end

      private

      def prompt_size(output)
        options = SIZES.map do |option|
          too_big = option.height > TTY::Screen.height || option.width * 2 - 1 > TTY::Screen.width
          disabled = '(screen too small)' if too_big
          {
            disabled: disabled,
            name: option.label,
            value: option,
          }
        end

        options << {
          name: 'Custom',
          value: :custom
        }

        prompt(interrupt: -> { exit 1 }).select('Size:', options, cycle: true)
      end

      def prompt_custom(output)
        min_width = 1
        max_width = TTY::Screen.width / 2 - 1
        width = prompt.ask("Width (#{min_width}-#{max_width})") do |q|
          q.required true
          q.convert :int
          q.validate do |val|
            val =~ /\d+/ && (min_width..max_width).include?(val.to_i)
          end
        end

        min_height = width == 1 ? 2 : 1
        max_height = TTY::Screen.height - 10 # leave room for interface
        height = prompt.ask("Height (#{min_height}-#{max_height})") do |q|
          q.required true
          q.convert :int
          q.validate do |val|
            val =~ /\d+/ && (min_height..max_height).include?(val.to_i)
          end
        end

        min_mines = 1
        max_mines = width * height - 1
        mines = prompt.ask("Mines (#{min_mines}-#{max_mines})") do |q|
          q.required true
          q.convert :int
          q.validate do |val|
            val =~ /\d+/ && (min_mines..max_mines).include?(val.to_i)
          end
        end

        GameTemplate.new('Custom', width, height, mines)
      end

      def clear_output(output)
        output.print cursor.hide
        output.print cursor.up(1)
        output.print cursor.clear_screen_down
        output.puts
      end
    end
  end
end
