# frozen_string_literal: true

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
      win: { fg: :green, modifiers: [:bold] },
      lose: { fg: :magenta, modifiers: [:bold] },
      clock: { fg: :cyan, modifiers: [:bold] },
      win_face: { fg: :yellow, modifiers: [:bold] },
      lose_face: { fg: :red, modifiers: [:bold] },
      play_face: { fg: :cyan, modifiers: [:bold] },
      mine: { fg: :red, modifiers: [:bold] },
      flag: { fg: :red, modifiers: [:bold] },
      mark: { fg: :magenta, modifiers: [:bold] },
      clue_0: { fg: :dark_gray },
      clue_1: { fg: :blue },
      clue_2: { fg: :green },
      clue_3: { fg: :magenta },
      clue_4: { fg: :cyan },
      clue_5: { fg: :red },
      clue_6: { fg: :yellow },
      clue_7: { fg: :magenta, modifiers: [:bold] },
      clue_8: { fg: :red, modifiers: [:bold] },
    }.freeze

    Theme.register(Theme.new(
                     name: 'modern',
                     sprites: MODERN_SPRITES,
                     colors: MODERN_COLORS
                   ))
  end
end
