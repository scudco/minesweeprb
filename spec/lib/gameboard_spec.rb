# frozen_string_literal: true

require 'minesweeprb/gameboard'

RSpec.describe Minesweeprb::Gameboard do
  let(:game) { Minesweeprb::Game.new(label: 'test', width: 10, height: 10, mines: 3) }

  before do
    mock_screen = double('screen', maxx: 80, maxy: 24)
    mock_window = double('window',
      keypad: nil, setpos: nil, refresh: nil, clrtoeol: nil,
      clear: nil, begy: 0, begx: 0, maxx: 80, maxy: 24,
      getch: 'q', attron: nil, "<<": nil
    )
    allow(mock_window).to receive(:attron).and_yield

    allow_any_instance_of(described_class).to receive(:init_screen).and_return(mock_screen)
    allow_any_instance_of(described_class).to receive(:use_default_colors)
    allow_any_instance_of(described_class).to receive(:start_color)
    allow_any_instance_of(described_class).to receive(:curs_set)
    allow_any_instance_of(described_class).to receive(:noecho)
    allow_any_instance_of(described_class).to receive(:ESCDELAY=)
    allow_any_instance_of(described_class).to receive(:mousemask)
    allow_any_instance_of(described_class).to receive(:init_pair)
    allow_any_instance_of(described_class).to receive(:close_screen)
    allow_any_instance_of(described_class).to receive(:color_pair).and_return(0)

    stub_const('Curses::Window', Class.new do
      def initialize(*); end
      def keypad(*); end
      def setpos(*); end
      def refresh; end
      def clrtoeol; end
      def clear; end
      def begy; 0; end
      def begx; 0; end
      def maxx; 80; end
      def maxy; 24; end
      def getch; 'q'; end
      def attron(*); yield if block_given?; end
      def <<(str); end
    end)
  end

  it 'initializes without error' do
    board = described_class.new(game)
    expect(board.game).to eq(game)
  end
end
