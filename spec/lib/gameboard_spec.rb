# frozen_string_literal: true

RSpec.describe Minesweeprb::Gameboard do
  it 'doesn’t blow up' do
    described_class.new(nil)
  end
end
