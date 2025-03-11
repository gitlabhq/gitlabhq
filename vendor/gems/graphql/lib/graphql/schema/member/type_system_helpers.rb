# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module TypeSystemHelpers
        def initialize(...)
          super
          @to_non_null_type ||= nil
          @to_list_type ||= nil
        end

        # @return [Schema::NonNull] Make a non-null-type representation of this type
        def to_non_null_type
          @to_non_null_type ||= GraphQL::Schema::NonNull.new(self)
        end

        # @return [Schema::List] Make a list-type representation of this type
        def to_list_type
          @to_list_type ||= GraphQL::Schema::List.new(self)
        end

        # @return [Boolean] true if this is a non-nullable type. A nullable list of non-nullables is considered nullable.
        def non_null?
          false
        end

        # @return [Boolean] true if this is a list type. A non-nullable list is considered a list.
        def list?
          false
        end

        def to_type_signature
          graphql_name
        end

        # @return [GraphQL::TypeKinds::TypeKind]
        def kind
          raise GraphQL::RequiredImplementationMissingError, "No `.kind` defined for #{self}"
        end

        private

        def inherited(subclass)
          subclass.class_exec do
            @to_non_null_type ||= nil
            @to_list_type ||= nil
          end
          super
        end
      end
    end
  end
end
