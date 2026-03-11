# frozen_string_literal: true

RSpec.describe Minesweeprb::Game do
  subject(:game) { described_class.new(label: 'Test', width: 5, height: 5, mines: 3) }

  describe '#initialize' do
    it 'sets dimensions' do
      expect(game.width).to eq(5)
      expect(game.height).to eq(5)
    end

    it 'sets mine count' do
      expect(game.mines).to eq(3)
    end

    it 'starts at center' do
      expect(game.active_square).to eq([2, 2])
    end

    it 'starts with empty collections' do
      expect(game.flagged_squares).to be_empty
      expect(game.marked_squares).to be_empty
      expect(game.revealed_squares).to be_empty
    end

    it 'is not started or over' do
      expect(game).not_to be_started
      expect(game).not_to be_over
    end
  end

  describe '#move' do
    it 'moves up' do
      game.move(:up)
      expect(game.active_square).to eq([2, 1])
    end

    it 'moves down' do
      game.move(:down)
      expect(game.active_square).to eq([2, 3])
    end

    it 'moves left' do
      game.move(:left)
      expect(game.active_square).to eq([1, 2])
    end

    it 'moves right' do
      game.move(:right)
      expect(game.active_square).to eq([3, 2])
    end

    it 'wraps horizontally' do
      3.times { game.move(:left) }
      expect(game.active_square).to eq([4, 2])
    end

    it 'wraps vertically' do
      3.times { game.move(:up) }
      expect(game.active_square).to eq([2, 4])
    end
  end

  describe '#cycle_flag' do
    # Use a large board so flood-fill doesn't reveal the target square
    let(:big_game) { described_class.new(label: 'Big', width: 9, height: 9, mines: 10) }

    before do
      big_game.reveal_active_square
      # Move to a corner — unlikely to be revealed by flood-fill from center
      big_game.active_square = [0, 0]
    end

    it 'flags an unrevealed square' do
      next if big_game.revealed_squares.include?(big_game.active_square)
      big_game.cycle_flag
      expect(big_game.flagged_squares).to include(big_game.active_square)
    end

    it 'cycles flag -> mark -> unflagged' do
      next if big_game.revealed_squares.include?(big_game.active_square)
      pos = big_game.active_square.dup

      big_game.cycle_flag
      expect(big_game.flagged_squares).to include(pos)

      big_game.cycle_flag
      expect(big_game.flagged_squares).not_to include(pos)
      expect(big_game.marked_squares).to include(pos)

      big_game.cycle_flag
      expect(big_game.flagged_squares).not_to include(pos)
      expect(big_game.marked_squares).not_to include(pos)
    end

    it 'does not flag a revealed square' do
      big_game.active_square = big_game.center
      big_game.cycle_flag
      expect(big_game.flagged_squares).to be_empty
    end

    it 'does not flag before first reveal' do
      fresh_game = described_class.new(label: 'T', width: 5, height: 5, mines: 3)
      fresh_game.cycle_flag
      expect(fresh_game.flagged_squares).to be_empty
    end
  end

  describe '#reveal_active_square' do
    it 'reveals the active square' do
      game.reveal_active_square
      expect(game.revealed_squares).not_to be_empty
    end

    it 'starts the timer on first reveal' do
      expect(game.start_time).to be_nil
      game.reveal_active_square
      expect(game.start_time).not_to be_nil
    end

    it 'does not reveal flagged squares' do
      # Use a dense board so flood-fill from center won't reach the corner
      dense = described_class.new(label: 'Dense', width: 9, height: 9, mines: 10)
      dense.reveal_active_square
      dense.active_square = [0, 0]
      next if dense.revealed_squares.include?(dense.active_square)
      dense.cycle_flag
      pos = dense.active_square.dup
      dense.reveal_active_square
      expect(dense.flagged_squares).to include(pos)
    end
  end

  describe '#play_grid' do
    it 'returns a 2D array of sprites' do
      grid = game.play_grid
      expect(grid.length).to eq(5)
      expect(grid.first.length).to eq(5)
    end

    it 'shows squares before reveal' do
      grid = game.play_grid
      expect(grid.flatten.uniq).to eq([Minesweeprb::Game::SPRITES[:square]])
    end

    it 'shows clues after reveal' do
      game.reveal_active_square
      grid = game.play_grid
      revealed_sprites = grid.flatten.uniq
      expect(revealed_sprites).not_to eq([Minesweeprb::Game::SPRITES[:square]])
    end
  end

  describe '#header' do
    it 'includes mine count and time' do
      header = game.header
      expect(header).to include('003') # mine count
      expect(header).to include('000') # time
    end
  end

  describe '#restart' do
    it 'resets the game state' do
      game.reveal_active_square
      game.restart
      expect(game.revealed_squares).to be_empty
      expect(game.active_square).to eq(game.center)
      expect(game.start_time).to be_nil
    end
  end

  describe 'win detection' do
    it 'detects a win when all non-mine squares are revealed' do
      # Use a tiny board to make winning feasible
      tiny = described_class.new(label: 'T', width: 2, height: 2, mines: 1)
      # Reveal squares until won or lost, restarting on loss
      attempts = 0
      loop do
        attempts += 1
        tiny.restart
        tiny.active_square = [0, 0]
        tiny.reveal_active_square
        next if tiny.lost?

        # Try revealing remaining squares
        [[1, 0], [0, 1], [1, 1]].each do |pos|
          break if tiny.over?
          tiny.active_square = pos
          tiny.reveal_active_square
        end

        break if tiny.won? || attempts > 100
      end
      expect(tiny).to be_won
    end
  end

  describe 'loss detection' do
    it 'detects a loss when a mine is revealed' do
      # Use a 3x3 board with 7 mines — only 2 safe squares
      # First reveal is always safe, then most other squares are mines
      dangerous = described_class.new(label: 'D', width: 3, height: 3, mines: 7)
      attempts = 0
      loop do
        attempts += 1
        dangerous.restart
        dangerous.active_square = [1, 1]
        dangerous.reveal_active_square
        next if dangerous.over? # won or lost on first reveal cascade

        # Try revealing all other squares until we hit a mine
        [[0, 0], [1, 0], [2, 0], [0, 1], [2, 1], [0, 2], [1, 2], [2, 2]].each do |pos|
          break if dangerous.over?
          dangerous.active_square = pos
          dangerous.reveal_active_square
        end
        break if dangerous.lost? || attempts > 100
      end
      expect(dangerous).to be_lost
    end
  end

  describe '#face' do
    it 'shows play face during play' do
      expect(game.face).to eq(Minesweeprb::Game::SPRITES[:play_face])
    end
  end

  describe '#game_over_message' do
    it 'returns WIN constant when won' do
      allow(game).to receive(:won?).and_return(true)
      expect(game.game_over_message).to eq(Minesweeprb::Game::SPRITES[:win_face] + " YOU WON " + Minesweeprb::Game::SPRITES[:win_face])
    end

    it 'returns LOSE constant when lost' do
      allow(game).to receive(:won?).and_return(false)
      allow(game).to receive(:lost?).and_return(true)
      expect(game.game_over_message).to eq(Minesweeprb::Game::SPRITES[:lose_face] + " GAME OVER " + Minesweeprb::Game::SPRITES[:lose_face])
    end
  end

  describe '#time' do
    it 'returns 0 before starting' do
      expect(game.time).to eq(0)
    end
  end

  describe '#remaining_mines' do
    it 'decreases when flags are placed' do
      dense = described_class.new(label: 'Dense', width: 9, height: 9, mines: 10)
      expect(dense.remaining_mines).to eq(10)
      dense.reveal_active_square
      dense.active_square = [0, 0]
      next if dense.revealed_squares.include?(dense.active_square)
      dense.cycle_flag
      expect(dense.remaining_mines).to eq(9)
    end
  end
end
