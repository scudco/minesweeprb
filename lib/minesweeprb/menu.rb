# frozen_string_literal: true

require 'curses'

module Minesweeprb
  class Menu
    include Curses

    QUIT_KEYS = ['q', 27, 127, KEY_BACKSPACE].freeze

    def self.select(title, options)
      new(title, options).select
    end

    def initialize(title, options)
      @title = title
      @options = options
      @selected = options.index { |o| !o[:disabled] } || 0
    end

    def select
      setup
      loop do
        draw
        case w_menu.getch
        when KEY_UP, 'k'
          move(-1)
        when KEY_DOWN, 'j'
          move(1)
        when 10, KEY_ENTER
          break @options[@selected][:value] unless @options[@selected][:disabled]
        when *QUIT_KEYS
          break nil
        end
      end
    end

    private

    def setup
      clear
      refresh

      init_pair(1, COLOR_CYAN, -1)
      init_pair(2, COLOR_WHITE, COLOR_CYAN)
      init_pair(3, COLOR_BLACK, -1)
      init_pair(4, COLOR_WHITE, -1)

      @hint = '(↑↓ or jk)Select (↵)Confirm (⎋)Quit'
      @separator = @options.length - 1
      rows = @options.length + 5
      cols = [max_label_width + 4, @hint.length + 2].max
      top = (lines - rows) / 2
      left = (::Curses.cols - cols) / 2
      @window = Window.new(rows, cols, top, left)
      @window.keypad(true)
    end

    def w_menu
      @window
    end

    def max_label_width
      widths = @options.map { |o|
        w = o[:name].length
        w += o[:disabled].length + 1 if o[:disabled]
        w
      }
      widths << @title.length
      widths.max
    end

    def move(delta)
      next_index = @selected
      loop do
        next_index = (next_index + delta) % @options.length
        break unless @options[next_index][:disabled]
        break if next_index == @selected
      end
      @selected = next_index unless @options[next_index][:disabled]
    end

    def draw
      w_menu.setpos(0, 0)
      w_menu.attron(color_pair(1)) { w_menu << " #{@title}" }
      w_menu.clrtoeol

      @options.each_with_index do |option, i|
        row = i + 1
        row += 1 if i >= @separator
        w_menu.setpos(row, 0)

        if option[:disabled]
          w_menu.attron(color_pair(3)) { w_menu << "  #{option[:name]} #{option[:disabled]}" }
        elsif i == @selected
          w_menu.attron(color_pair(2) | A_BOLD) { w_menu << "> #{option[:name]}" }
        else
          w_menu << "  #{option[:name]}"
        end

        w_menu.clrtoeol
      end

      w_menu.setpos(@options.length + 3, 0)
      w_menu.attron(color_pair(4)) { w_menu << " #{@hint}" }
      w_menu.clrtoeol

      w_menu.refresh
    end
  end
end
