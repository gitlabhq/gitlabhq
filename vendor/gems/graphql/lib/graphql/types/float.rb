# frozen_string_literal: true

module GraphQL
  module Types
    class Float < GraphQL::Schema::Scalar
      description "Represents signed double-precision fractional values as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_floating_point)."

      def self.coerce_input(value, _ctx)
        value.is_a?(Numeric) ? value.to_f : nil
      end

      def self.coerce_result(value, _ctx)
        value.to_f
      end

      default_scalar true
    end
  end
end
