# frozen_string_literal: true

module Minesweeprb
  class Game
    SPRITES = {
      clock: '◷',
      clues: '◻➊➋➌➍➎➏➐➑'.chars.freeze,
      flag: '✖', # ⚑ Flag does not work in curses?
      lose_face: '☹',
      mark: '⍰',
      mine: '☀',
      play_face: '☺',
      square: '◼',
      win_face: '☻',
    }.freeze
    WIN = "#{SPRITES[:win_face]} YOU WON #{SPRITES[:win_face]}"
    LOSE = "#{SPRITES[:lose_face]} GAME OVER #{SPRITES[:lose_face]}"

    attr_accessor :active_square
    attr_reader :flagged_squares,
      :height,
      :marked_squares,
      :mined_squares,
      :mines,
      :revealed_squares,
      :grid,
      :start_time,
      :width

    def initialize(label:, width:, height:, mines:)
      @width = width
      @height = height
      @mines = mines
      restart
    end

    def restart
      @active_square = center
      @flagged_squares = []
      @marked_squares = []
      @mined_squares = []
      @revealed_squares = {}
      @start_time = nil
      @end_time = nil
    end

    def remaining_mines
      mines - flagged_squares.length
    end

    def center
      [(width / 2).floor, (height / 2).floor]
    end

    def end_time
      @end_time || now
    end

    def time
      return 0 unless start_time

      end_time - start_time
    end

    def move(direction)
      return if over?

      x, y = active_square

      case direction
      when :up then y -= 1
      when :down then y += 1
      when :left then x -= 1
      when :right then x += 1
      end

      self.active_square = [x,y]
    end

    def active_square=(pos)
      x, y = pos
      x = x < 0 ? width - 1 : x
      x = x > width - 1 ? 0 : x
      y = y < 0 ? height - 1 : y
      y = y > height - 1 ? 0 : y

      @active_square = [x,y]
    end

    def face
      if won?
        SPRITES[:win_face]
      elsif lost?
        SPRITES[:lose_face]
      else
        SPRITES[:play_face]
      end
    end

    def header
      "#{SPRITES[:mine]} #{remaining_mines.to_s.rjust(3, '0')}" \
      "  #{face}  " \
      "#{SPRITES[:clock]} #{time.round.to_s.rjust(3, '0')}"
    end

    def cycle_flag
      return if over? || @revealed_squares.empty? || @revealed_squares.include?(active_square)

      if flagged_squares.include?(active_square)
        @flagged_squares -= [active_square]
        @marked_squares += [active_square]
      elsif marked_squares.include?(active_square)
        @marked_squares -= [active_square]
      elsif flagged_squares.length < mines
        @flagged_squares += [active_square]
      end
    end

    def reveal_active_square
      return if over? || flagged_squares.include?(active_square)

      reveal_square(active_square)
      @end_time = now if over?
    end

    def grid
      height.times.map do |y|
        width.times.map do |x|
          pos = [x,y]

          if mined_squares.include?(pos) && (revealed_squares[pos] || over?)
            SPRITES[:mine]
          elsif flagged_squares.include?(pos)
            SPRITES[:flag]
          elsif revealed_squares[pos]
            SPRITES[:clues][revealed_squares[pos]]
          elsif marked_squares.include?(pos)
            SPRITES[:mark]
          else
            SPRITES[:square]
          end
        end
      end
    end

    def started?
      !over? && revealed_squares.count > 0
    end

    def won?
      !lost? && revealed_squares.count == width * height - mines
    end

    def lost?
      (revealed_squares.keys & mined_squares).any?
    end

    def over?
      won? || lost?
    end

    def game_over_message
      won? ? WIN : LOSE
    end

    private

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def start_game
      place_mines
      @start_time = now
    end

    def place_mines
      mines.times do
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
      return if over? || flagged_squares.include?(active_square)
      start_game if revealed_squares.empty?
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
      (neighbors(square) & mined_squares).length
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
