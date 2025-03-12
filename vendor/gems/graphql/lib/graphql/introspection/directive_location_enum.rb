# frozen_string_literal: true
module GraphQL
  module Introspection
    class DirectiveLocationEnum < GraphQL::Schema::Enum
      graphql_name "__DirectiveLocation"
      description "A Directive can be adjacent to many parts of the GraphQL language, "\
                  "a __DirectiveLocation describes one such possible adjacencies."

      GraphQL::Schema::Directive::LOCATIONS.each do |location|
        value(location.to_s, GraphQL::Schema::Directive::LOCATION_DESCRIPTIONS[location], value: location, value_method: false)
      end
      introspection true
    end
  end
end
