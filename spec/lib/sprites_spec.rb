# frozen_string_literal: true

RSpec.describe "Minesweeprb::Game::SPRITES" do
  let(:sprites) { Minesweeprb::Game::SPRITES }

  it 'has all required keys' do
    expected_keys = %i[clock clues flag lose_face mark mine play_face square win_face]
    expect(sprites.keys.sort).to eq(expected_keys.sort)
  end

  it 'has 9 clue elements (0-8)' do
    expect(sprites[:clues].length).to eq(9)
  end

  it 'has non-empty values for all keys' do
    sprites.each do |key, value|
      if key == :clues
        expect(value).to all(be_a(String).and(satisfy { |s| !s.empty? }))
      else
        expect(value).to be_a(String)
        expect(value).not_to be_empty
      end
    end
  end

  it 'has frozen clues array' do
    expect(sprites[:clues]).to be_frozen
  end

  it 'is frozen' do
    expect(sprites).to be_frozen
  end
end
