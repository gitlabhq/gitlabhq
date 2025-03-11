# frozen_string_literal: true
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      class OneOf < GraphQL::Schema::Directive
        description "Requires that exactly one field must be supplied and that field must not be `null`."
        locations(GraphQL::Schema::Directive::INPUT_OBJECT)
        default_directive true

        def initialize(...)
          super

          owner.extend(IsOneOf)
        end

        module IsOneOf
          def one_of?
            true
          end
        end
      end
    end
  end
end
