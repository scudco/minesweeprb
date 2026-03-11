# frozen_string_literal: true

require 'curses'

module Minesweeprb
  class Gameboard
    include Curses

    RESTART = ['r'].freeze
    REVEAL = [10, KEY_ENTER].freeze
    FLAG = ['f', ' '].freeze
    BACK = ['q', 27, 127, KEY_BACKSPACE].freeze

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

    attr_reader :game, :windows, :game_x, :game_y

    def initialize(game, theme:)
      @game = game
      @theme = theme
      @active_square_sprite = theme.sprites[:active_square]
      build_color_map
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
      setup_windows
      @timer_thread = Thread.new do
        loop do
          paint_header
          sleep(0.5)
        end
      end

      paint_grid
      paint_grid while process_input(w_grid.getch)
    ensure
      @timer_thread&.kill
      windows.each_value do |w|
        w.close
      rescue StandardError
        nil
      end
      @windows = nil
    end

    private

    def build_color_map
      sprites = @theme.sprites
      colors = @theme.colors

      @color_entries = []
      @color_entries << [:win, colors[:win]]
      @color_entries << [:lose, colors[:lose]]
      @color_entries << [sprites[:clock], colors[:clock]]
      @color_entries << [sprites[:win_face], colors[:win_face]]
      @color_entries << [sprites[:lose_face], colors[:lose_face]]
      @color_entries << [sprites[:play_face], colors[:play_face]]
      @color_entries << [sprites[:mine], colors[:mine]]
      @color_entries << [sprites[:flag], colors[:flag]]
      @color_entries << [sprites[:mark], colors[:mark]]
      sprites[:clues].each_with_index do |char, i|
        @color_entries << [char, colors[:"clue_#{i}"]]
      end

      @color_map = {}
      @color_entries.each_with_index do |(key, _), i|
        @color_map[key] = i
      end
    end

    def setup_windows
      clear
      refresh

      screen_maxx = ::Curses.cols
      screen_maxy = lines

      @color_entries.each_with_index do |(_, color_def), i|
        fg, bg = color_def
        init_pair(i + 1, fg, bg || -1)
      end

      header = {
        top: 1,
        left: (screen_maxx - game.header.length) / 2,
        cols: game.header.length,
        rows: 1,
      }
      grid = {
        left: (screen_maxx - ((game.width * 2) - 1)) / 2,
        top: header[:top] + header[:rows] + 1,
        cols: (game.width * 2) - 1,
        rows: game.height,
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
        top: screen_maxy - 1,
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
    end

    def build_window(rows:, cols:, top:, left:)
      Window.new(rows, cols, top, left)
    end

    def process_input(key)
      case key
      when KEY_MOUSE then process_mouse(begin
        getmouse
      rescue StandardError
        nil
      end)
      when *MOVE.keys then game.move(MOVE[key])
      when *REVEAL then game.reveal_active_square
      when *FLAG then game.cycle_flag
      when *RESTART then game.restart
      when *BACK then return false
      end

      true
    end

    def process_mouse(mouse)
      top = w_grid.begy
      left = w_grid.begx
      bottom = top + game.height
      right = left + (game.width * 2) - 1
      on_board = (top..bottom).include?(mouse.y) &&
                 (left..right).include?(mouse.x) &&
                 (mouse.x - w_grid.begx).even?

      return if !on_board && !game.over?

      game.active_square = [(mouse.x - w_grid.begx) / 2, mouse.y - w_grid.begy]

      case mouse.bstate
      when BUTTON1_CLICKED then game.reveal_active_square
      when BUTTON2_CLICKED, (BUTTON_CTRL | BUTTON1_CLICKED) then game.cycle_flag
      end
    end

    def paint_header
      w_header.setpos(0, 0)

      game.header_segments.each do |role, text|
        case role
        when :face
          w_header.attron(color_for(text)) { w_header << text }
        when :mine, :clock
          sprite = game.sprites[role]
          w_header.attron(color_for(sprite)) { w_header << text }
        else
          w_header << text
        end
      end

      w_header.refresh
    end

    def paint_debug
      @color_entries.each do |(key, _)|
        w_debug.attron(color_for(key)) { w_debug << key.to_s }
      end
      w_debug.refresh
    end

    def paint_grid
      w_grid.setpos(0, 0)

      game.play_grid.each.with_index do |line, row|
        line.each.with_index do |char, col|
          w_grid.setpos(row, col * 2) if col < line.length

          if game.active_square == [col, row]
            active_char = @active_square_sprite && char == game.sprites[:square] ? @active_square_sprite : char
            w_grid.attron(color_for(char) | A_REVERSE) { w_grid << active_char }
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
        w_status.setpos(0, 0)
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
      instructions << '(⎋)Menu'

      w_instructions.setpos(0, 0)
      w_instructions << instructions.join(' ').center(w_instructions.maxx - 1)
    end

    def color_for(char)
      idx = @color_map[char]

      if idx
        color_pair(idx + 1)
      else
        0
      end
    end
  end
end
