# frozen_string_literal: true
module GraphQL
  class Schema
    class Scalar < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::ValidatesInput

      class << self
        def coerce_input(val, ctx)
          val
        end

        def coerce_result(val, ctx)
          val
        end

        def kind
          GraphQL::TypeKinds::SCALAR
        end

        def specified_by_url(new_url = nil)
          if new_url
            directive(GraphQL::Schema::Directive::SpecifiedBy, url: new_url)
          elsif (directive = directives.find { |dir| dir.graphql_name == "specifiedBy" })
            directive.arguments[:url] # rubocop:disable Development/ContextIsPassedCop
          elsif superclass.respond_to?(:specified_by_url)
            superclass.specified_by_url
          else
            nil
          end
        end

        def default_scalar(is_default = nil)
          if !is_default.nil?
            @default_scalar = is_default
          end
          @default_scalar
        end

        def default_scalar?
          @default_scalar ||= false
        end

        def validate_non_null_input(value, ctx, max_errors: nil)
          coerced_result = begin
            coerce_input(value, ctx)
          rescue GraphQL::CoercionError => err
            err
          rescue StandardError => err
            ctx.query.handle_or_reraise(err)
          end

          if coerced_result.nil?
            str_value = if value == Float::INFINITY
              ""
            else
              " #{GraphQL::Language.serialize(value)}"
            end
            Query::InputValidationResult.from_problem("Could not coerce value#{str_value} to #{graphql_name}")
          elsif coerced_result.is_a?(GraphQL::CoercionError)
            Query::InputValidationResult.from_problem(coerced_result.message, message: coerced_result.message, extensions: coerced_result.extensions)
          else
            nil
          end
        end
      end
    end
  end
end
