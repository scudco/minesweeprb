# frozen_string_literal: true

require 'pastel'

module Minesweeprb
  class Game
    DEFAULT_SIZE = 'Tiny'
    DEFAULT_MINE_COUNT = 1
    FLAG = '⚑'
    SQUARE = '◼'
    ACTIVE_SQUARE = '▣'
    MARK = '⍰'
    CLUES = '◻➊➋➌➍➎➏➐➑'.chars.freeze
    CLOCK = '◷'
    MINE = '☀'
    WON_FACE = '☻'
    LOST_FACE = '☹'
    PLAYING_FACE = '☺'
    SIZES = [
      {
        name: 'Tiny',
        width: 5,
        height: 5,
        mines: 3,
      },
      {
        name: 'Small',
        width: 9,
        height: 9,
        mines: 10,
      },
      {
        name: 'Medium',
        width: 13,
        height: 13,
        mines: 15,
      },
      {
        name: 'Large',
        width: 17,
        height: 17,
        mines: 20,
      },
      {
        name: 'Huge',
        width: 21,
        height: 21,
        mines: 25,
      },
    ].freeze

    attr_reader :active_square,
      :flagged_squares,
      :marked_squares,
      :mined_squares,
      :pastel,
      :revealed_squares,
      :size,
      :squares

    def initialize(size)
      @pastel = Pastel.new
      @size = SIZES[size]
      @active_square = center
      @flagged_squares = []
      @marked_squares = []
      @mined_squares = []
      @revealed_squares = {}
    end

    def mines
      size[:mines] - flagged_squares.size
    end

    def width
      size[:width]
    end

    def height
      size[:height]
    end

    def center
      [(width / 2).floor, (height / 2).floor]
    end

    def time
      0
    end

    def move(direction)
      return if over?

      x, y = @active_square

      case direction
      when :up then y -= 1
      when :down then y += 1
      when :left then x -= 1
      when :right then x += 1
      end

      x = x < 0 ? width - 1 : x
      x = x > width - 1 ? 0 : x
      y = y < 0 ? height - 1 : y
      y = y > height - 1 ? 0 : y

      @active_square = [x,y]
    end

    def face
      if won?
        WON_FACE
      elsif lost?
        LOST_FACE
      else
        PLAYING_FACE
      end
    end

    def header
      "#{MINE} #{mines.to_s.rjust(3, '0')}" \
      "  #{face}  " \
      "#{CLOCK} #{time.to_s.rjust(3, '0')}"
    end

    def cycle_flag
      return if over? || @revealed_squares.empty? || @revealed_squares.include?(active_square)

      if flagged_squares.include?(active_square)
        @flagged_squares -= [active_square]
        @marked_squares += [active_square]
      elsif marked_squares.include?(active_square)
        @marked_squares -= [active_square]
      elsif flagged_squares.length < size[:mines]
        @flagged_squares += [active_square]
      end
    end

    def reveal_active_square
      return if over? || flagged_squares.include?(active_square)

      reveal_square(active_square)
    end

    def squares
      height.times.map do |y|
        width.times.map do |x|
          pos = [x,y]

          if mined_squares.include?(pos) && (revealed_squares[pos] || over?)
            MINE
          elsif flagged_squares.include?(pos)
            FLAG
          elsif marked_squares.include?(pos)
            MARK
          elsif revealed_squares[pos]
            CLUES[revealed_squares[pos]]
          else
            SQUARE
          end
        end
      end
    end

    def started?
      !over? && revealed_squares.count > 0
    end

    def won?
      !lost? && revealed_squares.count == width * height - size[:mines]
    end

    def lost?
      (revealed_squares.keys & mined_squares).any?
    end

    def over?
      won? || lost?
    end

    private

    def place_mines
      size[:mines].times do
        pos = random_square
        pos = random_square while pos == active_square || mined_squares.include?(pos)
        @mined_squares << pos
      end
    end

    def random_square
      x = (1..width).to_a.sample - 1
      y = (1..height).to_a.sample - 1
      [x, y]
    end

    def reveal_square(square)
      place_mines if revealed_squares.empty?
      return if revealed_squares.keys.include?(square)
      return lose! if mined_squares.include?(square)

      value = square_value(square)
      @revealed_squares[square] = value
      neighbors(square).each { |neighbor| reveal_square(neighbor) } if value.zero?
    end

    def lose!
      @mined_squares.each { |square| @revealed_squares[square] = -1 }
    end

    def square_value(square)
      (neighbors(square) & mined_squares).size
    end

    def neighbors(square)
      [
        # top
        [square[0] - 1, square[1] - 1],
        [square[0] - 0, square[1] - 1],
        [square[0] + 1, square[1] - 1],

        # middle
        [square[0] - 1, square[1] - 0],
        [square[0] + 1, square[1] - 0],

        # bottom
        [square[0] - 1, square[1] + 1],
        [square[0] - 0, square[1] + 1],
        [square[0] + 1, square[1] + 1],
      ].select do |x,y|
        (0...width).include?(x) && (0...height).include?(y)
      end
    end
  end
end
