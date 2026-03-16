# frozen_string_literal: true

require 'ratatui_ruby'
require_relative 'splash'

module Minesweeprb
  class Menu
    QUIT_KEYS = %w[q esc backspace].freeze
    GEM_GAP = 2
    HINT = '(↑↓ or jk)Select (↵)Confirm (⎋)Quit'

    def self.select(title, options, tui)
      new(title, options, tui).select
    end

    def initialize(title, options, tui)
      @title = title
      @options = options
      @tui = tui
      @selected = options.index { |o| !o[:disabled] } || 0
    end

    def select
      loop do
        draw
        case @tui.poll_event
        in { type: :key, code: 'up' } | { type: :key, code: 'k' }
          move(-1)
        in { type: :key, code: 'down' } | { type: :key, code: 'j' }
          move(1)
        in { type: :key, code: 'enter' }
          break @options[@selected][:value] unless @options[@selected][:disabled]
        in { type: :key, code: code } if QUIT_KEYS.include?(code)
          break nil
        else
          nil
        end
      end
    end

    private

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
      @tui.draw do |frame|
        area = frame.area
        layout = pick_layout(area)
        render_layout(frame, area, layout)
      end
    end

    def pick_layout(area)
      menu_h = @options.length + 6
      menu_w = [max_label_width + 4, HINT.length + 2].max

      if fits_large?(area, menu_h)
        :large
      elsif fits_small?(area, menu_h, menu_w)
        :small
      else
        :none
      end
    end

    def fits_large?(area, menu_h)
      banner_w = art_w(Splash::GEM_LARGE) + GEM_GAP + art_w(Splash::TITLE_LARGE)
      banner_h = [art_h(Splash::GEM_LARGE), art_h(Splash::TITLE_LARGE) + 2].max
      banner_h + 1 + menu_h <= area.height && banner_w <= area.width
    end

    def fits_small?(area, menu_h, menu_w)
      banner_w = art_w(Splash::GEM_SMALL) + GEM_GAP + art_w(Splash::TITLE_SMALL)
      banner_h = [art_h(Splash::GEM_SMALL), art_h(Splash::TITLE_SMALL)].max
      h = banner_h + 3 + menu_h
      w = [banner_w, Splash::CREDIT.length, menu_w].max
      h <= area.height && w <= area.width
    end

    def art_h(art) = art.length
    def art_w(art) = art.map(&:length).max

    def max_label_width
      widths = @options.map do |o|
        w = o[:name].length
        w += o[:disabled].length + 1 if o[:disabled]
        w
      end
      widths << @title.length
      widths.max
    end

    def render_layout(frame, area, layout)
      case layout
      when :large then render_large(frame, area)
      when :small then render_small(frame, area)
      else render_menu_only(frame, area)
      end
    end

    def render_large(frame, area)
      gem_art = Splash::GEM_LARGE
      title_art = Splash::TITLE_LARGE
      banner_h = [art_h(gem_art), art_h(title_art) + 2].max
      rows = vsplit(area, [fill, len(banner_h), len(1), len(@options.length + 6), fill])

      render_banner(frame, rows[1], gem_art, title_art, credit_in_banner: true)
      render_menu_widget(frame, rows[3])
    end

    def render_small(frame, area)
      gem_art = Splash::GEM_SMALL
      title_art = Splash::TITLE_SMALL
      banner_h = [art_h(gem_art), art_h(title_art)].max
      rows = vsplit(area, [fill, len(banner_h), len(1), len(1), len(1), len(@options.length + 6), fill])

      render_banner(frame, rows[1], gem_art, title_art, credit_in_banner: false)
      render_credit(frame, rows[3])
      render_menu_widget(frame, rows[5])
    end

    def render_menu_only(frame, area)
      if Splash::CREDIT.length <= area.width
        rows = vsplit(area, [fill, len(1), len(1), len(@options.length + 6), fill])
        render_credit(frame, rows[1])
        render_menu_widget(frame, rows[3])
      else
        rows = vsplit(area, [fill, len(@options.length + 6), fill])
        render_menu_widget(frame, rows[1])
      end
    end

    def render_banner(frame, area, gem_art, title_art, credit_in_banner:)
      gem_w = art_w(gem_art)
      title_w = art_w(title_art)
      cols = hsplit(area, [fill, len(gem_w), len(GEM_GAP), len(title_w), fill])

      render_art(frame, cols[1], gem_art, splash_style)

      if credit_in_banner
        title_h = art_h(title_art)
        title_rows = vsplit(cols[3], [fill, len(title_h), len(1), len(1), fill])
        render_art(frame, title_rows[1], title_art, title_style)
        render_credit(frame, title_rows[3])
      else
        render_art(frame, cols[3], title_art, title_style)
      end
    end

    def render_art(frame, area, art, style)
      lines = art.map { |text| @tui.line(spans: [@tui.span(content: text, style: style)]) }
      frame.render_widget(@tui.paragraph(text: lines, alignment: :left), area)
    end

    def render_credit(frame, area)
      span = @tui.span(content: Splash::CREDIT, style: credit_style)
      frame.render_widget(
        @tui.paragraph(text: [@tui.line(spans: [span])], alignment: :center),
        area
      )
    end

    def render_menu_widget(frame, area)
      menu_w = [max_label_width + 4, HINT.length + 2].max
      centered = hsplit(area, [fill, len(menu_w), fill])[1]

      lines = build_menu_lines(menu_w)
      frame.render_widget(@tui.paragraph(text: lines), centered)
    end

    def build_menu_lines(menu_w)
      separator = @options.length - 1
      lines = [styled_line(@title.center(menu_w), menu_title_style), empty_line]

      @options.each_with_index do |option, i|
        lines << empty_line if i == separator
        lines << menu_option_line(option, i, menu_w)
      end

      lines << empty_line
      lines << styled_line(HINT.center(menu_w), hint_style)
    end

    def menu_option_line(option, index, menu_w)
      if option[:disabled]
        label = "#{option[:name]} #{option[:disabled]}"
        styled_line(label.center(menu_w), disabled_style)
      elsif index == @selected
        styled_line(option[:name].center(menu_w), selected_style)
      else
        styled_line(option[:name].center(menu_w), nil)
      end
    end

    def styled_line(text, style)
      @tui.line(spans: [@tui.span(content: text, style: style)])
    end

    def empty_line
      @tui.line(spans: [@tui.span(content: '')])
    end

    # Layout helpers
    def vsplit(area, constraints)
      @tui.layout_split(area, direction: :vertical, constraints: constraints)
    end

    def hsplit(area, constraints)
      @tui.layout_split(area, direction: :horizontal, constraints: constraints)
    end

    def fill = @tui.constraint_fill(1)
    def len(size) = @tui.constraint_length(size)

    # Style helpers
    def menu_title_style = @menu_title_style ||= @tui.style(fg: :cyan)
    def selected_style = @selected_style ||= @tui.style(fg: :white, bg: :cyan, modifiers: [:bold])
    def disabled_style = @disabled_style ||= @tui.style(fg: :dark_gray)
    def hint_style = @hint_style ||= @tui.style(fg: :white)
    def splash_style = @splash_style ||= @tui.style(fg: :red)
    def title_style = @title_style ||= @tui.style(fg: :red, modifiers: [:bold])
    def credit_style = @credit_style ||= @tui.style(fg: :cyan)
  end
end
