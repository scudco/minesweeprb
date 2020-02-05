# frozen_string_literal: true

module Minesweeprb
  class Gameboard
    DEFAULT_SIZE = 'Tiny'
    DEFAULT_MINE_COUNT = 1
    FLAG = '⚑'
    SQUARE = '◼'
    ACTIVE_SQUARE = '▣'
    CLUES = %w[◻➊➋➌➍➎➏].freeze
    CLOCK = '◷'
    MINE = '☀'
    FACE = '☻'
    SIZES = {
      'Tiny': {
        width: 5,
        height: 5,
        mines: 3,
      },
      'Small': {
        width: 9,
        height: 9,
        mines: 10,
      },
      'Medium': {
        width: 13,
        height: 13,
        mines: 15,
      },
      'Large': {
        width: 17,
        height: 17,
        mines: 20,
      },
      'Huge': {
        width: 21,
        height: 21,
        mines: 25,
      },
    }.freeze

    attr_reader :size

    def initialize(size)
      @size = SIZES[size]
    end

    def mines
      size[:mines]
    end

    def width
      size[:width]
    end

    def height
      size[:height]
    end

    def time
      0
    end

    def to_s
      ' ' \
        "#{MINE}(#{mines})  " \
        "#{FACE}  " \
        "#{CLOCK}(#{time})" \
        "\n\n" +
        height.times.map { ' ' + ([SQUARE] * width).join(' ') }.join("\n")
    end
  end
end
