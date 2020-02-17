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
      :mines,
      :revealed_squares,
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
      @revealed_squares = []
      @grid = Array.new(height) { Array.new(width) }
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
      return if over? || revealed_squares.empty? || revealed_squares.include?(active_square)

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
      return if over? || flagged_squares.include?(active_square) || revealed_squares.include?(active_square)

      return lose! if @mined_squares.include?(active_square)

      start_game if revealed_squares.empty?

      reveal(*active_square)

      @end_time = now if over?
    end

    def play_grid
      height.times.map do |y|
        width.times.map do |x|
          square = [x,y]

          if @mined_squares.include?(square) && (revealed_squares.include?(square) || over?)
            SPRITES[:mine]
          elsif revealed_squares.include?(square) || over?
            SPRITES[:clues][@grid[y][x]]
          elsif flagged_squares.include?(square)
            SPRITES[:flag]
          elsif marked_squares.include?(square)
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
      (revealed_squares & @mined_squares).any?
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
      place_clues
      @start_time = now
    end

    def place_mines
      mines.times do
        pos = random_square
        pos = random_square while pos == active_square || @mined_squares.include?(pos)
        @mined_squares << pos
      end
    end

    def random_square
      x = (1..width).to_a.sample - 1
      y = (1..height).to_a.sample - 1
      [x, y]
    end

    def place_clues
      width.times do |x|
        height.times do |y|
          @grid[y][x] = square_value(x,y)
        end
      end
    end

    def square_value(x,y)
      return if @mined_squares.include?([x,y])

      (neighbors(x,y) & @mined_squares).length
    end

    def reveal(x, y)
      @revealed_squares << [x, y]

      if @grid[y][x] == 0
        squares_to_visit =  (neighbors(x,y) - @revealed_squares)
        squares_to_visit.each { |x, y| reveal(x, y) }
      end
    end

    def lose!
      @revealed_squares |= @mined_squares
    end

    def neighbors(x,y)
      [
        # top
        [x - 1, y - 1],
        [x - 0, y - 1],
        [x + 1, y - 1],

        # sides
        [x - 1, y - 0],
        [x + 1, y - 0],

        # bottom
        [x - 1, y + 1],
        [x - 0, y + 1],
        [x + 1, y + 1],
      ].select do |x,y|
        x.between?(0, width-1) && y.between?(0, height-1)
      end
    end
  end
end
