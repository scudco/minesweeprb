# frozen_string_literal: true

require 'curses'
require 'timers'
require_relative './game'

module Minesweeprb
  class Gameboard
    include Curses

    RESTART = ['r'].freeze
    REVEAL = [10, KEY_ENTER].freeze
    FLAG = ['f', ' '].freeze
    QUIT = ['q', 27].freeze

    MOVE = {
      KEY_UP => :up,
      KEY_DOWN => :down,
      KEY_LEFT => :left,
      KEY_RIGHT => :right,
      'k' => :up,
      'j' => :down,
      'h' => :left,
      'l' => :right,
    }.freeze

    COLORS = {
      win: [A_BOLD | COLOR_GREEN],
      lose: [A_BOLD | COLOR_MAGENTA],
      Game::SPRITES[:clock] => [A_BOLD | COLOR_CYAN],
      Game::SPRITES[:win_face] => [A_BOLD | COLOR_YELLOW],
      Game::SPRITES[:lose_face] => [A_BOLD | COLOR_RED],
      Game::SPRITES[:play_face] => [A_BOLD | COLOR_CYAN],

      Game::SPRITES[:mine] => [A_BOLD | COLOR_RED],
      Game::SPRITES[:flag] => [A_BOLD | COLOR_RED],
      Game::SPRITES[:mark] => [A_BOLD | COLOR_MAGENTA],
      Game::SPRITES[:clues][0] => [COLOR_BLACK],
      Game::SPRITES[:clues][1] => [COLOR_BLUE],
      Game::SPRITES[:clues][2] => [COLOR_GREEN],
      Game::SPRITES[:clues][3] => [COLOR_MAGENTA],
      Game::SPRITES[:clues][4] => [COLOR_CYAN],
      Game::SPRITES[:clues][5] => [COLOR_RED],
      Game::SPRITES[:clues][6] => [COLOR_YELLOW],
      Game::SPRITES[:clues][7] => [A_BOLD | COLOR_MAGENTA],
      Game::SPRITES[:clues][8] => [A_BOLD | COLOR_RED],
    }.freeze

    COLOR_PAIRS = COLORS.keys.freeze

    attr_reader :game, :window, :game_x, :game_y

    def initialize(game)
      @game = game
      @timers = Timers::Group.new
      @game_timer = @timers.every(0.5) { paint }
      setup_curses
      Thread.new { loop { @timers.wait } }
    end

    def draw
      paint
      draw if process_input(window.getch)
    end

    def clear
      close_screen
    end

    private 

    def setup_curses
      init_screen
      use_default_colors
      start_color
      curs_set(0)
      noecho
      self.ESCDELAY = 1;
      mousemask(BUTTON1_CLICKED|BUTTON2_CLICKED|BUTTON3_CLICKED|BUTTON4_CLICKED)
      @window = Window.new(0, 0, 0, 0)
      @window.keypad(true)
      COLOR_PAIRS.each.with_index do |char, index|
        fg, bg = COLORS[char]
        init_pair(index + 1, fg, bg || -1)
      end
    end

    def process_input(key)
      case key
      when KEY_MOUSE then process_mouse(getmouse)
      when *MOVE.keys then game.move(MOVE[key])
      when *REVEAL then game.reveal_active_square
      when *FLAG then game.cycle_flag
      when *RESTART then game.restart
      when *QUIT then return false
      end

      true
    end

    def process_mouse(m)
      top = game_y
      left = game_x
      bottom = game_y + game.height
      right = game_x + game.width * 2 - 1
      on_board = (top..bottom).include?(m.y) &&
        (left..right).include?(m.x) &&
        (m.x - game_x).even?

      return if !on_board && !game.over?

      game.active_square = [(m.x - game_x) / 2, m.y - game_y]

      case m.bstate
        when BUTTON1_CLICKED then game.reveal_active_square
        when BUTTON2_CLICKED, (BUTTON_CTRL | BUTTON1_CLICKED) then game.cycle_flag
      end
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
      clrtoeol
      window << "\n"

      # COLOR_PAIRS.each do |char|
      #   window.attron(color_for(char)) { window << char }
      # end
      # clrtoeol
      # window << "\n"

      padding = (window.maxx - game.width * 2) / 2
      game.squares.each.with_index do |line, row|
        window << ' ' * padding
        @game_x, @game_y = window.curx, window.cury if row.zero?
        line.each.with_index do |char, col|
          if game.active_square == [col, row]
            window.attron(color_for(char) | A_REVERSE) { window << char }
          else
            window.attron(color_for(char)) { window << char }
          end
          window << ' ' if col < line.length
        end
        clrtoeol
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
        clrtoeol
        window << "\n"
      end

      window << "\n"
      window << how_to_play.center(window.maxx - 1)
      clrtoeol
      window << "\n"

      window.refresh
    end

    def color_for(char)
      pair = COLOR_PAIRS.index(char)

      if pair
        color_pair(pair + 1)
      else
        0
      end
    end
  end
end
