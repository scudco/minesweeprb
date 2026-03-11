# frozen_string_literal: true

require 'curses'

module Minesweeprb
  module Themes
    MODERN_SPRITES = {
      clock: '◷',
      clues: ['·', '1', '2', '3', '4', '5', '6', '7', '8'].freeze,
      flag: '⚑',
      lose_face: '☹',
      mark: '?',
      mine: '●',
      play_face: '☺',
      square: '■',
      active_square: '◼',
      win_face: '☻',
    }.freeze

    MODERN_COLORS = {
      win: [Curses::A_BOLD | Curses::COLOR_GREEN],
      lose: [Curses::A_BOLD | Curses::COLOR_MAGENTA],
      clock: [Curses::A_BOLD | Curses::COLOR_CYAN],
      win_face: [Curses::A_BOLD | Curses::COLOR_YELLOW],
      lose_face: [Curses::A_BOLD | Curses::COLOR_RED],
      play_face: [Curses::A_BOLD | Curses::COLOR_CYAN],
      mine: [Curses::A_BOLD | Curses::COLOR_RED],
      flag: [Curses::A_BOLD | Curses::COLOR_RED],
      mark: [Curses::A_BOLD | Curses::COLOR_MAGENTA],
      clue_0: [Curses::COLOR_BLACK],
      clue_1: [Curses::COLOR_BLUE],
      clue_2: [Curses::COLOR_GREEN],
      clue_3: [Curses::COLOR_MAGENTA],
      clue_4: [Curses::COLOR_CYAN],
      clue_5: [Curses::COLOR_RED],
      clue_6: [Curses::COLOR_YELLOW],
      clue_7: [Curses::A_BOLD | Curses::COLOR_MAGENTA],
      clue_8: [Curses::A_BOLD | Curses::COLOR_RED],
    }.freeze

    Theme.register(Theme.new(
                     name: 'modern',
                     sprites: MODERN_SPRITES,
                     colors: MODERN_COLORS
                   ))
  end
end
