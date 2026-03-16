# frozen_string_literal: true

require 'minesweeprb/commands/play'

RSpec.describe Minesweeprb::Commands::Play do
  let(:template) { Minesweeprb::GameTemplate.new(label: 'Tiny', width: 5, height: 5, mines: 3) }

  before do
    mock_tui = double('tui')
    mock_frame = double('frame')
    mock_area = double('area', width: 80, height: 24)

    allow(mock_frame).to receive(:area).and_return(mock_area)
    allow(mock_frame).to receive(:render_widget)
    allow(mock_tui).to receive(:draw).and_yield(mock_frame)
    areas = [mock_area, mock_area, mock_area, mock_area, mock_area]
    allow(mock_tui).to receive_messages(
      poll_event: double(none?: true, key?: false, mouse?: false),
      layout_split: areas,
      constraint_fill: double,
      constraint_length: double,
      paragraph: double,
      line: double,
      span: double,
      style: double,
      list: double
    )

    allow(RatatuiRuby).to receive(:run).and_yield(mock_tui)
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
