# frozen_string_literal: true

require 'minesweeprb/version'
require 'minesweeprb/game'
require 'minesweeprb/game_template'

module Minesweeprb
  class Error < StandardError; end

  autoload :Gameboard, 'minesweeprb/gameboard'
end
