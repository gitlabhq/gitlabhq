# frozen_string_literal: true
module GraphQL
  module Types
    class Boolean < GraphQL::Schema::Scalar
      description "Represents `true` or `false` values."

      def self.coerce_input(value, _ctx)
        (value == true || value == false) ? value : nil
      end

      def self.coerce_result(value, _ctx)
        !!value
      end

      default_scalar true
    end
  end
end
