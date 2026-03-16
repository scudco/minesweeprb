# frozen_string_literal: true

module Minesweeprb
  module Themes
    CLASSIC_SPRITES = {
      clock: '◷',
      clues: '◻➊➋➌➍➎➏➐➑'.chars.freeze,
      flag: '✖',
      lose_face: '☹',
      mark: '⍰',
      mine: '☀',
      play_face: '☺',
      square: '◼',
      win_face: '☻',
    }.freeze

    CLASSIC_COLORS = {
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
                     name: 'classic',
                     sprites: CLASSIC_SPRITES,
                     colors: CLASSIC_COLORS
                   ))
  end
end
