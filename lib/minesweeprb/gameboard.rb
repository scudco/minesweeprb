# frozen_string_literal: true

require 'curses'

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

    attr_reader :game, :windows, :game_x, :game_y

    def initialize(game)
      @game = game
      setup_curses
    end

    def w_header
      windows[:header]
    end

    def w_grid
      windows[:grid]
    end

    def w_status
      windows[:status]
    end

    def w_instructions
      windows[:instructions]
    end

    def w_debug
      windows[:debug]
    end

    def draw
      # paint_debug
      Thread.new do
        loop do
          paint_header
          sleep(0.5)
        end
      end

      paint_grid
      paint_grid while process_input(w_grid.getch)
    end

    def clear
      close_screen
    end

    private 

    def setup_curses
      screen = init_screen
      use_default_colors
      start_color
      curs_set(0)
      noecho
      self.ESCDELAY = 1;
      mousemask(BUTTON1_CLICKED|BUTTON2_CLICKED|BUTTON3_CLICKED|BUTTON4_CLICKED)

      header = {
        top: 1,
        left: (screen.maxx - game.header.length) / 2,
        cols: game.header.length,
        rows: 1,
      }
      grid = {
        left: (screen.maxx - (game.width * 2 - 1)) / 2,
        top: header[:top] + header[:rows] + 1,
        cols: game.width * 2 - 1, # leave room for spaces between squares
        rows: game.height,  # leave room for win/lose status and instructions
      }
      status = {
        left: 0,
        top: grid[:top] + grid[:rows] + 1,
        cols: 0,
        rows: 1,
      }
      instructions = {
        left: 0,
        top: status[:top] + status[:rows] + 1,
        cols: 0,
        rows: 1,
      }
      debug = {
        left: 0,
        top: screen.maxy - 1,
        cols: 0,
        rows: 1,
      }

      @windows = {}
      @windows[:header] = build_window(**header)
      @windows[:grid] = build_window(**grid)
      @windows[:status] = build_window(**status)
      @windows[:instructions] = build_window(**instructions)
      @windows[:debug] = build_window(**debug)
      @windows[:grid].keypad(true)

      COLORS.keys.each.with_index do |char, index|
        fg, bg = COLORS[char]
        init_pair(index + 1, fg, bg || -1)
      end
    end

    def build_window(rows:, cols:, top:, left:)
      Window.new(rows, cols, top, left)
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
      top = w_grid.begy
      left = w_grid.begx
      bottom = top + game.height
      right = left + game.width * 2 - 1
      on_board = (top..bottom).include?(m.y) &&
        (left..right).include?(m.x) &&
        (m.x - w_grid.begx).even?

      return if !on_board && !game.over?

      game.active_square = [(m.x - w_grid.begx) / 2, m.y - w_grid.begy]

      case m.bstate
        when BUTTON1_CLICKED then game.reveal_active_square
        when BUTTON2_CLICKED, (BUTTON_CTRL | BUTTON1_CLICKED) then game.cycle_flag
      end
    end

    def paint_header
      w_header.setpos(0,0)

      game.header.chars.each do |char|
        w_header.attron(color_for(char)) { w_header << char }
      end

      w_header.refresh
    end

    def paint_debug
      COLORS.keys.each do |char|
        w_debug.attron(color_for(char)) { w_debug << char.to_s }
      end
      w_debug.refresh
    end

    def paint_grid
      w_grid.setpos(0,0)

      game.play_grid.each.with_index do |line, row|
        line.each.with_index do |char, col|
          w_grid.setpos(row, col * 2) if col < line.length

          if game.active_square == [col, row]
            w_grid.attron(color_for(char) | A_REVERSE) { w_grid << char }
          else
            w_grid.attron(color_for(char)) { w_grid << char }
          end
        end
      end

      paint_status
      paint_instructions

      w_grid.refresh
      w_status.refresh
      w_instructions.refresh
    end

    def paint_status
      if game.over?
        w_status.setpos(0,0)
        outcome = game.won? ? :win : :lose
        message = game.game_over_message.center(w_status.maxx - 1)
        message.chars.each do |char|
          char_color = color_for(char)

          if char_color.zero?
            w_status.attron(color_for(outcome)) { w_status << char }
          else
            w_status.attron(char_color) { w_status << char }
          end
        end
      else
        w_status.clear
      end
    end

    def paint_instructions
      instructions = []
      instructions << '(←↓↑→ or hjkl)Move' unless game.over?
      instructions << '(f or ␣)Flag/Mark' if game.started?
      instructions << '(↵)Reveal' unless game.over?
      instructions << '(r)Restart'
      instructions << '(q or ⎋)Quit'

      w_instructions.setpos(0,0)
      w_instructions << instructions.join(' ').center(w_instructions.maxx - 1)
    end

    def color_for(char)
      pair = COLORS.keys.index(char)

      if pair
        color_pair(pair + 1)
      else
        0
      end
    end
  end
end
