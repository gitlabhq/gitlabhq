# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Test whether `ast_value` is a valid input for `type`
    class LiteralValidator
      def initialize(context:)
        @context = context
        @types = context.types
        @invalid_response = GraphQL::Query::InputValidationResult.new(valid: false, problems: [])
        @valid_response = GraphQL::Query::InputValidationResult.new(valid: true, problems: [])
      end

      def validate(ast_value, type)
        catch(:invalid) do
          recursively_validate(ast_value, type)
        end
      end

      private

      def replace_nulls_in(ast_value)
        case ast_value
        when Array
          ast_value.map { |v| replace_nulls_in(v) }
        when GraphQL::Language::Nodes::InputObject
          ast_value.to_h
        when GraphQL::Language::Nodes::NullValue
          nil
        else
          ast_value
        end
      end

      def recursively_validate(ast_value, type)
        if type.nil?
          # this means we're an undefined argument, see #present_input_field_values_are_valid
          maybe_raise_if_invalid(ast_value) do
            @invalid_response
          end
        elsif ast_value.is_a?(GraphQL::Language::Nodes::NullValue)
          maybe_raise_if_invalid(ast_value) do
            type.kind.non_null? ? @invalid_response : @valid_response
          end
        elsif type.kind.non_null?
          maybe_raise_if_invalid(ast_value) do
            ast_value.nil? ?
              @invalid_response :
              recursively_validate(ast_value, type.of_type)
          end
        elsif type.kind.list?
          item_type = type.of_type
          results = ensure_array(ast_value).map { |val| recursively_validate(val, item_type) }
          merge_results(results)
        elsif ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          @valid_response
        elsif type.kind.scalar? && constant_scalar?(ast_value)
          maybe_raise_if_invalid(ast_value) do
            ruby_value = replace_nulls_in(ast_value)
            type.validate_input(ruby_value, @context)
          end
        elsif type.kind.enum?
          maybe_raise_if_invalid(ast_value) do
            if ast_value.is_a?(GraphQL::Language::Nodes::Enum)
              type.validate_input(ast_value.name, @context)
            else
              # if our ast_value isn't an Enum it's going to be invalid so return false
              @invalid_response
            end
          end
        elsif type.kind.input_object? && ast_value.is_a?(GraphQL::Language::Nodes::InputObject)
          maybe_raise_if_invalid(ast_value) do
            merge_results([
              required_input_fields_are_present(type, ast_value),
              present_input_field_values_are_valid(type, ast_value)
            ])
          end
        else
          maybe_raise_if_invalid(ast_value) do
            @invalid_response
          end
        end
      end

      # When `error_bubbling` is false, we want to bail on the first failure that we find.
      # Use `throw` to escape the current call stack, returning the invalid response.
      def maybe_raise_if_invalid(ast_value)
        ret = yield
        if !@context.schema.error_bubbling && !ret.valid?
          throw(:invalid, ret)
        else
          ret
        end
      end

      # The GraphQL grammar supports variables embedded within scalars but graphql.js
      # doesn't support it so we won't either for simplicity
      def constant_scalar?(ast_value)
        if ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          false
        elsif ast_value.is_a?(Array)
          ast_value.all? { |element| constant_scalar?(element) }
        elsif ast_value.is_a?(GraphQL::Language::Nodes::InputObject)
          ast_value.arguments.all? { |arg| constant_scalar?(arg.value) }
        else
          true
        end
      end

      def required_input_fields_are_present(type, ast_node)
        # TODO - would be nice to use these to create an error message so the caller knows
        # that required fields are missing
        required_field_names = @types.arguments(type)
          .select { |argument| argument.type.kind.non_null? && !argument.default_value? }
          .map!(&:name)

        present_field_names = ast_node.arguments.map(&:name)
        missing_required_field_names = required_field_names - present_field_names
        if @context.schema.error_bubbling
          missing_required_field_names.empty? ? @valid_response : @invalid_response
        else
          results = missing_required_field_names.map do |name|
            arg_type = @types.argument(type, name).type
            recursively_validate(GraphQL::Language::Nodes::NullValue.new(name: name), arg_type)
          end
          if type.one_of? && ast_node.arguments.size != 1
            results << Query::InputValidationResult.from_problem("`#{type.graphql_name}` is a OneOf type, so only one argument may be given (instead of #{ast_node.arguments.size})")
          end
          merge_results(results)
        end
      end

      def present_input_field_values_are_valid(type, ast_node)
        results = ast_node.arguments.map do |value|
          field = @types.argument(type, value.name)
          # we want to call validate on an argument even if it's an invalid one
          # so that our raise exception is on it instead of the entire InputObject
          field_type = field && field.type
          recursively_validate(value.value, field_type)
        end
        merge_results(results)
      end

      def ensure_array(value)
        value.is_a?(Array) ? value : [value]
      end

      def merge_results(results_list)
        merged_result = Query::InputValidationResult.new
        results_list.each do |inner_result|
          merged_result.merge_result!([], inner_result)
        end
        merged_result
      end
    end
  end
end
