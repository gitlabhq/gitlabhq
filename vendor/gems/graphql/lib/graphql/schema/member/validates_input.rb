# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module ValidatesInput
        def valid_input?(val, ctx)
          validate_input(val, ctx).valid?
        end

        def validate_input(val, ctx, max_errors: nil)
          if val.nil?
            Query::InputValidationResult::VALID
          else
            validate_non_null_input(val, ctx, max_errors: max_errors) || Query::InputValidationResult::VALID
          end
        end

        def valid_isolated_input?(v)
          valid_input?(v, GraphQL::Query::NullContext.instance)
        end

        def coerce_isolated_input(v)
          coerce_input(v, GraphQL::Query::NullContext.instance)
        end

        def coerce_isolated_result(v)
          coerce_result(v, GraphQL::Query::NullContext.instance)
        end
      end
    end
  end
end
