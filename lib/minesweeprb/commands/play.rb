# frozen_string_literal: true

require 'ratatui_ruby'
require_relative '../../minesweeprb'
require_relative '../menu'
require_relative '../theme'

module Minesweeprb
  module Commands
    class Play
      SIZES = [
        # [ label, width, height, # of mines ]
        ['Tiny',    5,  5, 3],
        ['Small',   9,  9, 10],
        ['Medium', 13, 13, 15],
        ['Large',  17, 17, 20],
        ['Huge',   21, 21, 25],
      ].map { |label, width, height, mines| GameTemplate.new(label:, width:, height:, mines:) }.freeze

      def initialize(options)
        @options = options
        @theme = @options[:theme] ? Theme[@options[:theme]] : Theme.default
      end

      def execute
        RatatuiRuby.run do |tui|
          loop do
            template = prompt_size(tui)
            break if template.nil?

            game = Game.new(**template.to_h, sprites: @theme.sprites)
            Gameboard.new(game, theme: @theme).draw(tui)
          end
        end
      end

      # Gameboard chrome: 1 top margin + 1 header + 1 gap + grid + 1 gap + 1 status + 1 gap + 1 instructions
      BOARD_CHROME_ROWS = 7

      private

      def prompt_size(tui)
        screen_area = nil
        tui.draw { |frame| screen_area = frame.area }

        options = SIZES.map do |tmpl|
          too_tall = tmpl.height + BOARD_CHROME_ROWS > screen_area.height
          too_wide = (tmpl.width * 2) - 1 > screen_area.width
          disabled = '(screen too small)' if too_tall || too_wide
          {
            disabled: disabled,
            name: tmpl.label,
            value: tmpl,
          }
        end

        options << { name: 'Quit', value: nil }

        Menu.select('Choose a size:', options, tui)
      end
    end
  end
end
