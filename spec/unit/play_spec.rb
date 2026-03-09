# frozen_string_literal: true

require 'minesweeprb/commands/play'

RSpec.describe Minesweeprb::Commands::Play do
  let(:template) { Minesweeprb::GameTemplate.new(label: 'Tiny', width: 5, height: 5, mines: 3) }

  before do
    mock_console = double('console', winsize: [24, 80])
    allow(IO).to receive(:console).and_return(mock_console)

    allow_any_instance_of(described_class).to receive(:init_screen)
    allow_any_instance_of(described_class).to receive(:use_default_colors)
    allow_any_instance_of(described_class).to receive(:start_color)
    allow_any_instance_of(described_class).to receive(:curs_set)
    allow_any_instance_of(described_class).to receive(:noecho)
    allow_any_instance_of(described_class).to receive(:ESCDELAY=)
    allow_any_instance_of(described_class).to receive(:mousemask)
    allow_any_instance_of(described_class).to receive(:close_screen)
  end

  it 'executes play command with a selected size' do
    mock_board = double('gameboard', draw: nil)

    allow(Minesweeprb::Menu).to receive(:select).and_return(template, nil)
    allow(Minesweeprb::Gameboard).to receive(:new).and_return(mock_board)

    command = described_class.new({})
    command.execute

    expect(Minesweeprb::Gameboard).to have_received(:new)
    expect(mock_board).to have_received(:draw)
  end

  it 'exits gracefully when menu is cancelled' do
    allow(Minesweeprb::Menu).to receive(:select).and_return(nil)

    command = described_class.new({})
    command.execute

    expect(Minesweeprb::Menu).to have_received(:select)
  end
end
