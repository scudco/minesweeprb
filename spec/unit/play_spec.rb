require 'minesweeprb/commands/play'

RSpec.describe Minesweeprb::Commands::Play do
  it "executes `play` command successfully" do
    output = StringIO.new
    options = {}
    command = Minesweeprb::Commands::Play.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
