# frozen_string_literal: true

require 'io/console'
require 'curses'
require_relative '../../minesweeprb'
require_relative '../menu'

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

          game = Game.new(**template.to_h)
          Gameboard.new(game).draw
        end
      ensure
        close_screen
      end

      private

      def prompt_size
        height, width = IO.console.winsize

        options = SIZES.map do |tmpl|
          too_big = tmpl.height > height || tmpl.width * 2 - 1 > width
          disabled = '(screen too small)' if too_big
          {
            disabled: disabled,
            name: tmpl.label,
            value: tmpl,
          }
        end

        options << { name: 'Quit', value: nil }

        Menu.select('Size:', options)
      end
    end
  end
end
