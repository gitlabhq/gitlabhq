# frozen_string_literal: true
require 'ostruct'
require 'support/mongoid_setup'

module StarTrek
  names = [
    'USS Enterprise',
    'USS Excelsior',
    'USS Reliant',
    'IKS Koraga',
    'IKS Kronos One',
    'IRW Khazara',
    'IRW Praetus',
  ]

  # Set up "Bases" in MongoDB
  class Base
    include Mongoid::Document
    field :name, type: String
    field :sector, type: String
    field :faction_id, type: Integer
    has_many :residents, class_name: 'StarTrek::Resident', inverse_of: :base
  end

  class Resident
    include Mongoid::Document
    field :name, type: String
    belongs_to :base, class_name: 'StarTrek::Base'
  end

  Base.collection.drop

  dsk7 = Base.create!(name: "Deep Space Station K-7", sector: "Mempa", faction_id: 1)
  dsk7.residents.create!(name: "Shir th'Talias")
  dsk7.residents.create!(name: "Lurry")
  dsk7.residents.create!(name: "Mackenzie Calhoun")

  r1 = Base.create!(name: "Regula I", sector: "Mutara", faction_id: 1)
  r1.residents.create!(name: "V. Madison")
  r1.residents.create!(name: "D. March")
  r1.residents.create!(name: "C. Marcus")

  Base.create!(name: "Deep Space Nine", sector: "Bajoran", faction_id: 1)
  Base.create!(name: "Firebase P'ok", sector: nil, faction_id: 2)
  Base.create!(name: "Ganalda Space Station", sector: "Archanis", faction_id: 2)
  Base.create!(name: "Rh'Ihho Station", sector: "Rator", faction_id: 3)


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

  federation = FactionRecord.new(
    id: '1',
    name: 'United Federation of Planets',
    ships:  ['1', '2', '3'],
    bases: Base.where(faction_id: 1),
    bases_clone: Base.where(faction_id: 1),
  )

  klingon = FactionRecord.new(
    id: '2',
    name: 'Klingon Empire',
    ships: ['4', '5'],
    bases: Base.where(faction_id: 2),
    bases_clone: Base.where(faction_id: 2),
  )

  romulan = FactionRecord.new(
    id: '2',
    name: 'Romulan Star Empire',
    ships: ['6', '7'],
    bases: Base.where(faction_id: 3),
    bases_clone: Base.where(faction_id: 3),
  )

  DATA = {
    "Faction" => {
      "1" => federation,
      "2" => klingon,
      "3" => romulan,
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
