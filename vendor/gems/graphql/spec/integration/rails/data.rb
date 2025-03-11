# frozen_string_literal: true
require 'ostruct'
require "support/active_record_setup"

module StarWars
  names = [
    'X-Wing',
    'Y-Wing',
    'A-Wing',
    'Millennium Falcon',
    'Home One',
    'TIE Fighter',
    'TIE Interceptor',
    'Executor',
  ]

  class StarWarsModel < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: { writing: :starwars, reading: :starwars_replica }
  end

  StarWarsModel.establish_connection(:starwars)
  class Base < StarWarsModel
  end

  Base.create!(name: "Yavin", planet: "Yavin 4", faction_id: 1)
  Base.create!(name: "Echo Base", planet: "Hoth", faction_id: 1)
  Base.create!(name: "Secret Hideout", planet: "Dantooine", faction_id: 1)
  Base.create!(name: "Death Star", planet: nil, faction_id: 2)
  Base.create!(name: "Shield Generator", planet: "Endor", faction_id: 2)
  Base.create!(name: "Headquarters", planet: "Coruscant", faction_id: 2)

  class SequelBase < Sequel::Model(:bases)
  end

  class FactionRecord
    attr_reader :id, :name, :ships, :bases, :bases_clone
    def initialize(id:, name:, ships:, bases:, bases_clone:)
      @id = id
      @name = name
      @ships = ships
      @bases = bases
      @bases_clone = bases_clone
    end
  end

  rebels  = FactionRecord.new(
    id: '1',
    name: 'Alliance to Restore the Republic',
    ships:  ['1', '2', '3', '4', '5'],
    bases: Base.where(faction_id: 1),
    bases_clone: Base.where(faction_id: 1),
  )


  empire = FactionRecord.new(
    id: '2',
    name: 'Galactic Empire',
    ships: ['6', '7', '8'],
    bases: Base.where(faction_id: 2),
    bases_clone: Base.where(faction_id: 2),
  )

  DATA = {
    "Faction" => {
      "1" => rebels,
      "2" => empire,
    },
    "Ship" => names.each_with_index.reduce({}) do |memo, (name, idx)|
      id = (idx + 1).to_s
      memo[id] = OpenStruct.new(name: name, id: id)
      memo
    end,
    "Base" => Hash.new { |h, k| h[k] = Base.find(k) }
  }

  def DATA.create_ship(name, faction_id)
    new_id = (self["Ship"].keys.map(&:to_i).max + 1).to_s
    new_ship = OpenStruct.new(id: new_id, name: name)
    self["Ship"][new_id] = new_ship
    self["Faction"][faction_id].ships << new_id
    new_ship
  end
end
