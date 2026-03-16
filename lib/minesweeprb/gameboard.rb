# frozen_string_literal: true

require 'ratatui_ruby'

module Minesweeprb
  class Gameboard
    RESTART = ['r'].freeze
    REVEAL = ['enter'].freeze
    FLAG = ['f', ' '].freeze
    BACK = %w[q esc backspace].freeze

    MOVE = {
      'up' => :up,
      'down' => :down,
      'left' => :left,
      'right' => :right,
      'k' => :up,
      'j' => :down,
      'h' => :left,
      'l' => :right,
    }.freeze

    attr_reader :game

    def initialize(game, theme:)
      @game = game
      @theme = theme
      @active_square_sprite = theme.sprites[:active_square]
      build_color_map
    end

    def draw(tui)
      loop do
        tui.draw do |frame|
          render(tui, frame)
        end

        event = tui.poll_event(timeout: 0.5)

        if event.none?
          next # timeout — re-render to update timer
        end

        break unless process_input(tui, event)
      end
    end

    private

    def build_color_map
      sprites = @theme.sprites
      colors = @theme.colors

      @color_map = {}
      @color_map[:win] = colors[:win]
      @color_map[:lose] = colors[:lose]
      @color_map[sprites[:clock]] = colors[:clock]
      @color_map[sprites[:win_face]] = colors[:win_face]
      @color_map[sprites[:lose_face]] = colors[:lose_face]
      @color_map[sprites[:play_face]] = colors[:play_face]
      @color_map[sprites[:mine]] = colors[:mine]
      @color_map[sprites[:flag]] = colors[:flag]
      @color_map[sprites[:mark]] = colors[:mark]
      sprites[:clues].each_with_index do |char, i|
        @color_map[char] = colors[:"clue_#{i}"]
      end
    end

    def style_for(tui, key)
      color_def = @color_map[key]
      return nil unless color_def

      tui.style(**color_def)
    end

    def render(tui, frame)
      area = frame.area

      # Layout: margin(1) + header(1) + gap(1) + grid(height) + gap(1) + status(1) + gap(1) + instructions(1)
      rows = tui.layout_split(
        area,
        direction: :vertical,
        constraints: [
          tui.constraint_length(1),                # top margin
          tui.constraint_length(1),                # header
          tui.constraint_length(1),                # gap
          tui.constraint_length(game.height),      # grid
          tui.constraint_length(1),                # gap
          tui.constraint_length(1),                # status
          tui.constraint_length(1),                # gap
          tui.constraint_length(1),                # instructions
        ]
      )

      header_area = rows[1]
      grid_area = rows[3]
      status_area = rows[5]
      instructions_area = rows[7]

      render_header(tui, frame, header_area)
      render_grid(tui, frame, grid_area)
      render_status(tui, frame, status_area)
      render_instructions(tui, frame, instructions_area)
    end

    def render_header(tui, frame, area)
      spans = game.header_segments.map do |role, text|
        case role
        when :face
          style = style_for(tui, text)
          tui.span(content: text, style: style)
        when :mine, :clock
          sprite = game.sprites[role]
          style = style_for(tui, sprite)
          tui.span(content: text, style: style)
        else
          tui.span(content: text)
        end
      end

      frame.render_widget(
        tui.paragraph(text: [tui.line(spans: spans)], alignment: :center),
        area
      )
    end

    def render_grid(tui, frame, area)
      grid_w = (game.width * 2) - 1

      # Center the grid horizontally
      cols = tui.layout_split(
        area,
        direction: :horizontal,
        constraints: [
          tui.constraint_fill(1),
          tui.constraint_length(grid_w),
          tui.constraint_fill(1),
        ]
      )
      centered_area = cols[1]

      lines = game.play_grid.map.with_index do |row_data, row|
        spans = row_data.flat_map.with_index do |char, col|
          cell_spans = []
          cell_spans << tui.span(content: ' ') if col.positive?

          if game.active_square == [col, row]
            active_char = @active_square_sprite && char == game.sprites[:square] ? @active_square_sprite : char
            base = @color_map[char] || {}
            active_style = tui.style(**base, modifiers: (base[:modifiers] || []) + [:reversed])
            cell_spans << tui.span(content: active_char, style: active_style)
          else
            style = style_for(tui, char)
            cell_spans << tui.span(content: char, style: style)
          end

          cell_spans
        end

        tui.line(spans: spans)
      end

      frame.render_widget(tui.paragraph(text: lines), centered_area)
    end

    def render_status(tui, frame, area)
      return unless game.over?

      outcome = game.won? ? :win : :lose
      message = game.game_over_message
      outcome_style = style_for(tui, outcome)

      spans = message.chars.map do |char|
        char_style = style_for(tui, char)
        tui.span(content: char, style: char_style || outcome_style)
      end

      frame.render_widget(
        tui.paragraph(text: [tui.line(spans: spans)], alignment: :center),
        area
      )
    end

    def render_instructions(tui, frame, area)
      parts = []
      parts << '(←↓↑→ or hjkl)Move' unless game.over?
      parts << '(f or ␣)Flag/Mark' if game.started?
      parts << '(↵)Reveal' unless game.over?
      parts << '(r)Restart'
      parts << '(⎋)Menu'

      frame.render_widget(
        tui.paragraph(text: parts.join(' '), alignment: :center),
        area
      )
    end

    def process_input(tui, event)
      if event.key?
        process_key(event)
      elsif event.mouse?
        process_mouse(tui, event)
        true
      else
        true
      end
    end

    def process_key(event)
      code = event.code

      case code
      when *MOVE.keys then game.move(MOVE[code])
      when *REVEAL then game.reveal_active_square
      when *FLAG then game.cycle_flag
      when *RESTART then game.restart
      when *BACK then return false
      end

      true
    end

    def process_mouse(tui, event)
      return unless event.mouse?

      col, row = mouse_to_grid(tui, event.x, event.y)
      return if col.nil? && !game.over?

      game.active_square = [col, row] if col

      return unless event.kind == 'down'

      if event.modifiers&.include?('ctrl')
        game.cycle_flag
      else
        game.reveal_active_square
      end
    end

    def mouse_to_grid(tui, x, y)
      grid_top = 3
      area = nil
      tui.draw { |frame| area = frame.area }
      grid_w = (game.width * 2) - 1
      grid_left = (area.width - grid_w) / 2

      return nil unless y >= grid_top && y < grid_top + game.height
      return nil unless x >= grid_left && x < grid_left + grid_w
      return nil unless ((x - grid_left) % 2).zero?

      [(x - grid_left) / 2, y - grid_top]
    end
  end
end
