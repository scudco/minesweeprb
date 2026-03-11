# frozen_string_literal: true

RSpec.describe '`minesweeprb` command', type: :cli do
  it 'prints version with --version flag' do
    output = `bundle exec ruby exe/minesweeprb --version`
    expect(output.strip).to match(/\Av\d+\.\d+\.\d+(\.\w+)?\z/)
  end

  it 'prints help with --help flag' do
    output = `bundle exec ruby exe/minesweeprb --help`
    expect(output).to include('Usage: minesweeprb')
    expect(output).to include('--version')
    expect(output).to include('--theme')
    expect(output).to include('--help')
  end
end
