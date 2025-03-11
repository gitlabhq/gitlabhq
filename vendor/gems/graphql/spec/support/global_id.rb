# frozen_string_literal: true

if defined?(GlobalID)
  GlobalID.app = "graphql-ruby-test"

  class GlobalIDUser
    include GlobalID::Identification

    attr_reader :id

    def initialize(id, located_many: false)
      @id = id
      @located_many = located_many
    end

    def located_many?
      @located_many
    end

    def self.find(id_or_ids)
      if id_or_ids.is_a?(Array)
        id_or_ids.map { |id| new(id, located_many: true) }
      else
        new(id_or_ids)
      end
    end

    def ==(that)
      self.id == that.id
    end
  end
end
