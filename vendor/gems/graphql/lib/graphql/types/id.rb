# frozen_string_literal: true
module GraphQL
  module Types
    class ID < GraphQL::Schema::Scalar
      graphql_name "ID"
      description "Represents a unique identifier that is Base64 obfuscated. It is often used to refetch an object or as key for a cache. The ID type appears in a JSON response as a String; however, it is not intended to be human-readable. When expected as an input type, any string (such as `\"VXNlci0xMA==\"`) or integer (such as `4`) input value will be accepted as an ID."
      default_scalar true
      def self.coerce_result(value, _ctx)
        value.is_a?(::String) ? value : value.to_s
      end

      def self.coerce_input(value, _ctx)
        case value
        when ::String
          value
        when Integer
          value.to_s
        else
          nil
        end
      end
    end
  end
end
