# frozen_string_literal: true
require "spec_helper"

module InstrumentationSpec
  module SomeInterface
    include GraphQL::Schema::Interface
    field :never_called, String, null: false

    def never_called
      "should never be called"
    end
  end

  class SomeType < GraphQL::Schema::Object
    implements SomeInterface
  end

  class Query < GraphQL::Schema::Object
    field :some_field, [SomeInterface]

    def some_field
      nil
    end
  end

  class Schema < GraphQL::Schema
    query Query
    orphan_types [SomeType]
  end
end
