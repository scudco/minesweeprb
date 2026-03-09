# frozen_string_literal: true

RSpec.describe Minesweeprb::Gameboard do
  it 'doesn’t blow up' do
    described_class.new(Minesweeprb::Game.new(label: 'test', width: 10, height: 10, mines: 3))
  end
end
