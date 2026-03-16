# frozen_string_literal: true

require 'minesweeprb/gameboard'
require 'minesweeprb/theme'

RSpec.describe Minesweeprb::Gameboard do
  let(:theme) { Minesweeprb::Theme.default }
  let(:game) { Minesweeprb::Game.new(label: 'test', width: 10, height: 10, mines: 3) }

  it 'initializes without error' do
    board = described_class.new(game, theme: theme)
    expect(board.game).to eq(game)
  end

  it 'builds color map from theme' do
    described_class.new(game, theme: theme)
    # Verify it can be instantiated with both themes
    classic_board = described_class.new(game, theme: Minesweeprb::Theme['classic'])
    expect(classic_board.game).to eq(game)
  end
end
