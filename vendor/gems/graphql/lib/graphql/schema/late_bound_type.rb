# frozen_string_literal: true
module GraphQL
  class Schema
    # A stand-in for a type which will be resolved in a given schema, by name.
    # TODO: support argument types too, make this a public API somehow
    # @api Private
    class LateBoundType
      attr_reader :name
      alias :graphql_name :name
      def initialize(local_name)
        @name = local_name
        @to_non_null_type = nil
        @to_list_type = nil
      end

      def unwrap
        self
      end

      def to_non_null_type
        @to_non_null_type ||= GraphQL::Schema::NonNull.new(self)
      end

      def to_list_type
        @to_list_type ||= GraphQL::Schema::List.new(self)
      end

      def to_type_signature
        name
      end

      def inspect
        "#<LateBoundType @name=#{name}>"
      end

      def non_null?
        false
      end

      alias :to_s :inspect
    end
  end
end
