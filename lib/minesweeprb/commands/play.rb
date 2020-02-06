# frozen_string_literal: true

require 'pastel'
require 'timers'
require 'tty-reader'
require 'tty-screen'

require_relative '../command'
require_relative '../game'

module Minesweeprb
  module Commands
    class Play < Minesweeprb::Command
      VIM_MAPPING = {
        'k' => :up,
        'j' => :down,
        'h' => :left,
        'l' => :right,
      }.freeze

      attr_reader :game, :game_timer, :pastel, :timers

      def initialize(options)
        @options = options
        @pastel = Pastel.new
        @timers = Timers::Group.new
      end

      def start_game(output)
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

        @game = Minesweeprb::Game.new(size)

        print_gameboard(output)
      end

      def how_to_play
        instructions = []
        instructions << '(←↓↑→ or hjkl) Move' unless game.over?
        instructions << '(f or ␣)Flag/Mark' if game.started?
        instructions << '(↵)Reveal' unless game.over?
        instructions << '(r)Restart'
        instructions << '(q)Quit'
        instructions.join('  ')
      end

      def execute(input: $stdin, output: $stdout)
        start_game(output)

        reader
          .on(:keyescape) { exit }
          .on(:keyalpha) do |event|
            key = event.value.downcase
            case key
            when 'q' then exit
            when 'r'
              output.print cursor.clear_screen_down
              start_game(output)
            when 'f'
              unless game.over?
                game.cycle_flag
                print_gameboard(output)
              end
            when 'j', 'k', 'h', 'l'
              unless game.over?
                game.move(VIM_MAPPING[key])
                print_gameboard(output)
              end
            end

          end.on(:keypress) do |event|
            unless game.over?
              case event.key.name
              when :up, :down, :left, :right
                game.move(event.key.name)
              when :space
                game.cycle_flag
              when :return
                game.reveal_active_square
              end

              print_gameboard(output)
            end
          end

        loop { reader.read_keypress }
      end

      def reader
        @reader ||= TTY::Reader.new
      end

      def print_gameboard(output)
        total_height = game.height + game.header.lines.length + 1
        output.print cursor.clear_lines(total_height, :down)
        output.print cursor.up(total_height - 2)

        game.header.each_line do |line|
          chars = line.chars.map do |char|
            case char
            when Game::WON_FACE then pastel.bright_yellow(char)
            when Game::LOST_FACE then pastel.bright_red(char)
            when Game::PLAYING_FACE then pastel.bright_cyan(char)
            when Game::MINE then pastel.bright_red(char)
            when Game::CLOCK then pastel.bright_cyan(char)
            else
              char
            end
          end

          center(output, chars.join)
        end

        game.squares.each.with_index do |row, y|
          line = row.map.with_index do |char, x|
            char = case char
                   when Game::FLAG then pastel.bright_red(char)
                   when Game::MINE
                     if game.won?
                       pastel.bright_green(char)
                     elsif game.active_square == [x,y]
                       pastel.black.on_bright_red(char)
                     else
                       pastel.bright_red(char)
                     end
                   when Game::MARK then pastel.bright_magenta(char)
                   when Game::CLUES[0] then pastel.dim(char)
                   when Game::CLUES[1] then pastel.blue(char)
                   when Game::CLUES[2] then pastel.green(char)
                   when Game::CLUES[3] then pastel.red(char)
                   when Game::CLUES[4] then pastel.magenta(char)
                   when Game::CLUES[5] then pastel.black(char)
                   when Game::CLUES[6] then pastel.bright_red(char)
                   when Game::CLUES[7] then pastel.bright_white(char)
                   when Game::CLUES[8] then pastel.bright_cyan(char)
                   else
                     char
                   end

            !game.over? && game.active_square == [x,y] ? pastel.inverse(char): char
          end.join(' ')

          center(output, line)
        end

        output.print cursor.clear_screen_down
        output.puts

        if game.over?
          message = if game.won?
                      pastel.bright_green.bold('☻ YOU WON ☻')
                    elsif game.lost?
                      pastel.bright_magenta.bold('☹ GAME OVER ☹')
                    end

          center(output, message)
          output.puts
          center(output, how_to_play)
        else
          center(output, how_to_play)
          output.print cursor.up(total_height + 2)
        end
      end

      def center(output, line)
        width = TTY::Screen.width
        padding = (width - (pastel.strip(line.chomp.strip).length)) / 2
        output.print(' ' * [padding, 0].max)
        output.puts line
      end
    end
  end
end
