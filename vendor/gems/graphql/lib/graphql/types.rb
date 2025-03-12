# frozen_string_literal: true

module GraphQL
  module Types
    extend Autoload

    autoload :Boolean, "graphql/types/boolean"
    autoload :BigInt, "graphql/types/big_int"
    autoload :Float, "graphql/types/float"
    autoload :ID, "graphql/types/id"
    autoload :Int, "graphql/types/int"
    autoload :JSON, "graphql/types/json"
    autoload :String, "graphql/types/string"
    autoload :ISO8601Date, "graphql/types/iso_8601_date"
    autoload :ISO8601DateTime, "graphql/types/iso_8601_date_time"
    autoload :ISO8601Duration, "graphql/types/iso_8601_duration"
    autoload :Relay, "graphql/types/relay"
  end
end
