# frozen_string_literal: true

require 'io/console'
require 'curses'
require_relative '../../minesweeprb'
require_relative '../menu'
require_relative '../theme'

module Minesweeprb
  module Commands
    class Play
      include Curses

      SIZES = [
        # [ label, width, height, # of mines ]
        ['Tiny',    5,  5,  3],
        ['Small',   9,  9, 10],
        ['Medium', 13, 13, 15],
        ['Large',  17, 17, 20],
        ['Huge',   21, 21, 25],
      ].map { |label, width, height, mines| GameTemplate.new(label:, width:, height:, mines:) }.freeze

      def initialize(options)
        @options = options
        @theme = @options[:theme] ? Theme[@options[:theme]] : Theme.default
      end

      def execute(input: $stdin, output: $stdout)
        init_screen
        use_default_colors
        start_color
        curs_set(0)
        noecho
        self.ESCDELAY = 1
        mousemask(BUTTON1_CLICKED|BUTTON2_CLICKED|BUTTON3_CLICKED|BUTTON4_CLICKED)

        loop do
          template = prompt_size
          break if template.nil?

          game = Game.new(**template.to_h, sprites: @theme.sprites)
          Gameboard.new(game, theme: @theme).draw
        end
      ensure
        close_screen
      end

      private

      # Gameboard chrome: 1 top margin + 1 header + 1 gap + grid + 1 gap + 1 status + 1 gap + 1 instructions
      BOARD_CHROME_ROWS = 7

      def prompt_size
        screen_rows, screen_cols = IO.console.winsize

        options = SIZES.map do |tmpl|
          too_tall = tmpl.height + BOARD_CHROME_ROWS > screen_rows
          too_wide = tmpl.width * 2 - 1 > screen_cols
          disabled = '(screen too small)' if too_tall || too_wide
          {
            disabled: disabled,
            name: tmpl.label,
            value: tmpl,
          }
        end

        options << { name: 'Quit', value: nil }

        Menu.select('Choose a size:', options)
      end
    end
  end
end
