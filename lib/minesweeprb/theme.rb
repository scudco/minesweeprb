# frozen_string_literal: true

module Minesweeprb
  class Theme
    attr_reader :name, :sprites, :colors

    def initialize(name:, sprites:, colors:)
      @name = name
      @sprites = sprites.freeze
      @colors = colors.freeze
    end

    @registry = {}

    class << self
      def register(theme)
        @registry[theme.name] = theme
      end

      def [](name)
        @registry[name] || raise(ArgumentError, "Unknown theme: #{name}. Available: #{names.join(', ')}")
      end

      def names
        @registry.keys
      end

      def default
        @registry['modern']
      end
    end
  end
end

require_relative 'themes/classic'
require_relative 'themes/modern'
