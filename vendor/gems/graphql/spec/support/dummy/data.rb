# frozen_string_literal: true
require 'ostruct'
module Dummy
  module Data
    Cheese = Struct.new(:id, :flavor, :origin, :fat_content, :source) do
      def ==(other)
        # This is buggy on purpose -- it shouldn't be called during execution.
        other.id == id
      end

      # Alias for when this is treated as milk in EdibleAsMilkInterface
      def fatContent # rubocop:disable Naming/MethodName
        fat_content
      end
    end

    Milk = Struct.new(:id, :fat_content, :origin, :source, :flavors)
    Cow = Struct.new(:id, :name, :last_produced_dairy)
    Goat = Struct.new(:id, :name, :last_produced_dairy)
  end

  CHEESES = {
    1 => Data::Cheese.new(1, "Brie", "France", 0.19, 1),
    2 => Data::Cheese.new(2, "Gouda", "Netherlands", 0.3, 1),
    3 => Data::Cheese.new(3, "Manchego", "Spain", 0.065, "SHEEP")
  }

  MILKS = {
    1 => Data::Milk.new(1, 0.04, "Antiquity", 1, ["Natural", "Chocolate", "Strawberry"]),
  }

  DAIRY = OpenStruct.new(
    id: 1,
    cheese: CHEESES[1],
    milks: [MILKS[1]]
  )

  COWS = {
    1 => Data::Cow.new(1, "Billy", MILKS[1])
  }

  GOATS = {
    1 => Data::Goat.new(1, "Gilly", MILKS[1]),
  }
end
