# frozen_string_literal: true

require 'curses'
require 'timers'
require_relative './game'

module Minesweeprb
  class Gameboard
    RESTART = ['r'].freeze
    REVEAL = [10, Curses::KEY_ENTER].freeze
    FLAG = ['f', ' '].freeze
    QUIT = ['q', 27].freeze

    MOVE = {
      Curses::KEY_UP => :up,
      Curses::KEY_DOWN => :down,
      Curses::KEY_LEFT => :left,
      Curses::KEY_RIGHT => :right,
      'k' => :up,
      'j' => :down,
      'h' => :left,
      'l' => :right,
    }.freeze

    COLORS = {
      win: [Curses::A_BOLD | Curses::COLOR_GREEN],
      lose: [Curses::A_BOLD | Curses::COLOR_MAGENTA],
      Game::SPRITES[:clock] => [Curses::A_BOLD | Curses::COLOR_CYAN],
      Game::SPRITES[:win_face] => [Curses::A_BOLD | Curses::COLOR_YELLOW],
      Game::SPRITES[:lose_face] => [Curses::A_BOLD | Curses::COLOR_RED],
      Game::SPRITES[:play_face] => [Curses::A_BOLD | Curses::COLOR_CYAN],

      Game::SPRITES[:mine] => [Curses::A_BOLD | Curses::COLOR_RED],
      Game::SPRITES[:flag] => [Curses::A_BOLD | Curses::COLOR_RED],
      Game::SPRITES[:mark] => [Curses::A_BOLD | Curses::COLOR_MAGENTA],
      Game::SPRITES[:clues][0] => [Curses::COLOR_BLACK],
      Game::SPRITES[:clues][1] => [Curses::COLOR_BLUE],
      Game::SPRITES[:clues][2] => [Curses::COLOR_GREEN],
      Game::SPRITES[:clues][3] => [Curses::COLOR_MAGENTA],
      Game::SPRITES[:clues][4] => [Curses::COLOR_CYAN],
      Game::SPRITES[:clues][5] => [Curses::COLOR_RED],
      Game::SPRITES[:clues][6] => [Curses::COLOR_YELLOW],
      Game::SPRITES[:clues][7] => [Curses::A_BOLD | Curses::COLOR_MAGENTA],
      Game::SPRITES[:clues][8] => [Curses::A_BOLD | Curses::COLOR_RED],
    }.freeze

    COLOR_PAIRS = COLORS.keys.freeze

    attr_reader :game, :pastel, :window

    def initialize(size)
      @pastel = Pastel.new
      @game = Game.new(size)
      @timers = Timers::Group.new
      @game_timer = @timers.every(0.5) { paint }
      Thread.new { loop { @timers.wait } }
      setup_curses
    end

    def draw
      paint
      draw if process_input(window.getch)
    end

    def clear
      Curses.close_screen
    end

    private 

    def setup_curses
      Curses.init_screen
      Curses.use_default_colors
      Curses.start_color
      Curses.curs_set(0)
      Curses.noecho
      Curses.ESCDELAY = 1;
      @window = Curses::Window.new(0, 0, 0, 0)
      @window.keypad(true)
      COLOR_PAIRS.each.with_index do |char, index|
        fg, bg = COLORS[char]
        Curses.init_pair(index + 1, fg, bg || -1)
      end
    end

    def process_input(key)
      case key
      when *MOVE.keys then game.move(MOVE[key])
      when *REVEAL then game.reveal_active_square
      when *FLAG then game.cycle_flag
      when *RESTART then game.restart
      when *QUIT then return false
      end

      true
    end

    def how_to_play
      instructions = []
      instructions << '(←↓↑→ or hjkl)Move' unless game.over?
      instructions << '(f or ␣)Flag/Mark' if game.started?
      instructions << '(↵)Reveal' unless game.over?
      instructions << '(r)Restart'
      instructions << '(q or ⎋)Quit'
      instructions.join('  ')
    end

    def paint
      window.clear
      window << "\n"
      game.header.center(window.maxx - 1).chars.each do |char|
        window.attron(color_for(char)) { window << char }
      end
      Curses.clrtoeol
      window << "\n"

      # COLOR_PAIRS.each do |char|
      #   window.attron(color_for(char)) { window << char }
      # end
      # Curses.clrtoeol
      # window << "\n"

      padding = (window.maxx - game.width * 2) / 2
      game.squares.each.with_index do |line, row|
        window << ' ' * padding
        line.each.with_index do |char, col|
          if game.active_square == [col, row]
            window.attron(color_for(char) | Curses::A_REVERSE) { window << char }
          else
            window.attron(color_for(char)) { window << char }
          end
          window << ' ' if col < line.length
        end
        Curses.clrtoeol
        window << "\n"
      end

      if game.over?
        window << "\n"
        outcome = game.won? ? :win : :lose
        message = game.game_over_message.center(window.maxx - 1)
        message.chars.each do |char|
          char_color = color_for(char)

          if char_color.zero?
            window.attron(color_for(outcome)) { window << char }
          else
            window.attron(char_color) { window << char }
          end
        end
        Curses.clrtoeol
        window << "\n"
      end

      window << "\n"
      window << how_to_play.center(window.maxx - 1)
      Curses.clrtoeol
      window << "\n"

      window.refresh
    end

    def color_for(char)
      pair = COLOR_PAIRS.index(char)

      if pair
        Curses.color_pair(pair + 1)
      else
        0
      end
    end
  end
end
