# frozen_string_literal: true

require 'curses'
require_relative 'splash'

module Minesweeprb
  class Menu
    include Curses

    QUIT_KEYS = ['q', 27, 127, KEY_BACKSPACE].freeze
    GEM_GAP = 2

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

      init_pair(1, COLOR_CYAN, -1)    # menu title
      init_pair(2, COLOR_WHITE, COLOR_CYAN) # selected option
      init_pair(3, COLOR_BLACK, -1)  # disabled option
      init_pair(4, COLOR_WHITE, -1)  # hint text
      init_pair(5, COLOR_RED, -1)    # splash art
      init_pair(6, COLOR_CYAN, -1)   # credit link

      @hint = '(↑↓ or jk)Select (↵)Confirm (⎋)Quit'
      @separator = @options.length - 1

      pick_layout
      build_windows
    end

    def pick_layout
      @screen_h = lines
      @screen_w = ::Curses.cols
      @menu_h = @options.length + 6
      @menu_w = [max_label_width + 4, @hint.length + 2].max
      @credit_h = 2

      try_large || try_small || (@layout = :none)
    end

    # Large: large gem left + large title right, credit right-aligned under title
    def try_large
      gem = Splash::GEM_LARGE
      title = Splash::TITLE_LARGE
      banner_w = art_w(gem) + GEM_GAP + art_w(title)
      # Credit sits 1 line below title on the right side, within banner height
      title_h_with_credit = art_h(title) + 1 + 1
      banner_h = [art_h(gem), title_h_with_credit].max
      h = banner_h + 1 + @menu_h
      w = [banner_w, @menu_w].max
      return false unless h <= @screen_h && w <= @screen_w

      @layout = :large
      @gem_art = gem
      @title_art = title
      true
    end

    # Small: small gem left + small title right, credit centered below
    def try_small
      gem = Splash::GEM_SMALL
      title = Splash::TITLE_SMALL
      banner_w = art_w(gem) + GEM_GAP + art_w(title)
      banner_h = [art_h(gem), art_h(title)].max
      h = banner_h + 1 + 1 + 1 + @menu_h # banner + gap + credit + gap + menu
      w = [banner_w, Splash::CREDIT.length, @menu_w].max
      return false unless h <= @screen_h && w <= @screen_w

      @layout = :small
      @gem_art = gem
      @title_art = title
      true
    end

    def art_h(art) = art.length
    def art_w(art) = art.map(&:length).max

    def build_windows
      case @layout
      when :large then build_large
      when :small then build_small
      else build_menu_only
      end

      @window.keypad(true)
    end

    def build_large
      gem_h = art_h(@gem_art)
      gem_w = art_w(@gem_art)
      title_h = art_h(@title_art)
      title_w = art_w(@title_art)
      credit_w = Splash::CREDIT.length
      banner_w = gem_w + GEM_GAP + title_w
      title_h_with_credit = title_h + 1 + 1
      banner_h = [gem_h, title_h_with_credit].max
      total_h = banner_h + 1 + @menu_h

      row = [(@screen_h - total_h) / 2, 0].max
      banner_left = (@screen_w - banner_w) / 2
      title_left = banner_left + gem_w + GEM_GAP

      gem_top = row + (banner_h - gem_h) / 2
      @gem_window = Window.new(gem_h, gem_w + 1, gem_top, banner_left)

      title_top = row + (banner_h - title_h_with_credit) / 2
      @title_window = Window.new(title_h, title_w + 1, title_top, title_left)

      credit_top = title_top + title_h + 1
      @credit_window = Window.new(1, credit_w + 1, credit_top, title_left)

      row += banner_h + 1
      @window = Window.new(@menu_h, @menu_w, row, (@screen_w - @menu_w) / 2)
    end

    def build_small
      gem_h = art_h(@gem_art)
      gem_w = art_w(@gem_art)
      title_h = art_h(@title_art)
      title_w = art_w(@title_art)
      credit_w = Splash::CREDIT.length
      banner_w = gem_w + GEM_GAP + title_w
      banner_h = [gem_h, title_h].max
      total_h = banner_h + 1 + 1 + 1 + @menu_h

      row = [(@screen_h - total_h) / 2, 0].max
      banner_left = (@screen_w - banner_w) / 2

      gem_top = row + (banner_h - gem_h) / 2
      @gem_window = Window.new(gem_h, gem_w + 1, gem_top, banner_left)

      title_left = banner_left + gem_w + GEM_GAP
      title_top = row + (banner_h - title_h) / 2
      @title_window = Window.new(title_h, title_w + 1, title_top, title_left)
      row += banner_h + 1

      @credit_window = Window.new(1, credit_w + 1, row, (@screen_w - credit_w) / 2)
      row += 2

      @window = Window.new(@menu_h, @menu_w, row, (@screen_w - @menu_w) / 2)
    end

    def build_menu_only
      credit_w = Splash::CREDIT.length
      total_h = @credit_h + @menu_h
      row = [(@screen_h - total_h) / 2, 0].max

      if credit_w <= @screen_w
        @credit_window = Window.new(1, credit_w + 1, row, (@screen_w - credit_w) / 2)
        row += @credit_h
      end

      @window = Window.new(@menu_h, @menu_w, row, (@screen_w - @menu_w) / 2)
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
      draw_splash
      draw_menu
    end

    def draw_splash
      if @gem_window && @gem_art
        @gem_art.each_with_index do |line, i|
          @gem_window.setpos(i, 0)
          @gem_window.attron(color_pair(5)) { @gem_window << line }
        end
        @gem_window.refresh
      end

      if @title_window
        @title_art.each_with_index do |line, i|
          @title_window.setpos(i, 0)
          @title_window.attron(color_pair(5) | A_BOLD) { @title_window << line }
        end
        @title_window.refresh
      end

      if @credit_window
        @credit_window.setpos(0, 0)
        @credit_window.attron(color_pair(6)) { @credit_window << Splash::CREDIT }
        @credit_window.refresh
      end
    end

    def draw_menu
      cols = @menu_w

      w_menu.setpos(0, 0)
      w_menu.attron(color_pair(1)) { w_menu << @title.center(cols) }

      @options.each_with_index do |option, i|
        row = i + 2
        row += 1 if i >= @separator
        w_menu.setpos(row, 0)

        if option[:disabled]
          label = "#{option[:name]} #{option[:disabled]}"
          w_menu.attron(color_pair(3)) { w_menu << label.center(cols) }
        elsif i == @selected
          w_menu.attron(color_pair(2) | A_BOLD) { w_menu << option[:name].center(cols) }
        else
          w_menu << option[:name].center(cols)
        end
      end

      w_menu.setpos(@options.length + 4, 0)
      w_menu.attron(color_pair(4)) { w_menu << @hint.center(cols) }

      w_menu.refresh
    end
  end
end
