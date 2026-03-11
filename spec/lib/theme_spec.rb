# frozen_string_literal: true

require 'minesweeprb/theme'

RSpec.describe Minesweeprb::Theme do
  let(:required_sprite_keys) { %i[clock clues flag lose_face mark mine play_face square win_face] }
  let(:optional_sprite_keys) { %i[active_square] }
  let(:required_color_keys) do
    %i[win lose clock win_face lose_face play_face mine flag mark clue_0 clue_1 clue_2 clue_3 clue_4 clue_5 clue_6 clue_7
       clue_8]
  end

  describe '.names' do
    it 'includes classic and modern' do
      expect(described_class.names).to include('classic', 'modern')
    end
  end

  describe '.default' do
    it 'returns the modern theme' do
      expect(described_class.default.name).to eq('modern')
    end
  end

  describe '.[]' do
    it 'looks up themes by name' do
      expect(described_class['modern'].name).to eq('modern')
    end

    it 'raises on unknown theme' do
      expect { described_class['nonexistent'] }.to raise_error(ArgumentError, /Unknown theme/)
    end
  end

  described_class.names.each do |name|
    describe "#{name} theme" do
      let(:theme) { described_class[name] }

      it 'has all required sprite keys' do
        extra = theme.sprites.keys - required_sprite_keys - optional_sprite_keys
        missing = required_sprite_keys - theme.sprites.keys
        expect(missing).to be_empty, "Missing keys: #{missing}"
        expect(extra).to be_empty, "Unexpected keys: #{extra}"
      end

      it 'has 9 clue elements' do
        expect(theme.sprites[:clues].length).to eq(9)
      end

      it 'has all required color keys' do
        expect(theme.colors.keys.sort).to eq(required_color_keys.sort)
      end

      it 'has non-empty sprite values' do
        theme.sprites.each do |key, value|
          if key == :clues
            expect(value).to all(be_a(String).and(satisfy { |s| !s.empty? }))
          else
            expect(value).to be_a(String)
            expect(value).not_to be_empty
          end
        end
      end
    end
  end
end
