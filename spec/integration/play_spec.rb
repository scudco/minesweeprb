RSpec.describe "`minesweeprb play` command", type: :cli do
  it "executes `minesweeprb help play` command successfully" do
    output = `minesweeprb help play`
    expected_output = <<-OUT
Usage:
  minesweeprb play

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
