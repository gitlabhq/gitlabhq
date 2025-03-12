# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this validator to require _one_ of the named arguments to be present.
      # Or, use Arrays of symbols to name a valid _set_ of arguments.
      #
      # (This is for specifying mutually exclusive sets of arguments.)
      #
      # @example Require exactly one of these arguments
      #
      #   field :update_amount, IngredientAmount, null: false do
      #     argument :ingredient_id, ID, required: true
      #     argument :cups, Integer, required: false
      #     argument :tablespoons, Integer, required: false
      #     argument :teaspoons, Integer, required: false
      #     validates required: { one_of: [:cups, :tablespoons, :teaspoons] }
      #   end
      #
      # @example Require one of these _sets_ of arguments
      #
      #  field :find_object, Node, null: true do
      #    argument :node_id, ID, required: false
      #    argument :object_type, String, required: false
      #    argument :object_id, Integer, required: false
      #    # either a global `node_id` or an `object_type`/`object_id` pair is required:
      #    validates required: { one_of: [:node_id, [:object_type, :object_id]] }
      #  end
      #
      # @example require _some_ value for an argument, even if it's null
      #   field :update_settings, AccountSettings do
      #     # `required: :nullable` means this argument must be given, but may be `null`
      #     argument :age, Integer, required: :nullable
      #   end
      #
      class RequiredValidator < Validator
        # @param one_of [Array<Symbol>] A list of arguments, exactly one of which is required for this field
        # @param argument [Symbol] An argument that is required for this field
        # @param message [String]
        def initialize(one_of: nil, argument: nil, message: nil, **default_options)
          @one_of = if one_of
            one_of
          elsif argument
            [argument]
          else
            raise ArgumentError, "`one_of:` or `argument:` must be given in `validates required: {...}`"
          end
          @message = message
          super(**default_options)
        end

        def validate(_object, context, value)
          fully_matched_conditions = 0
          partially_matched_conditions = 0

          if !value.nil?
            @one_of.each do |one_of_condition|
              case one_of_condition
              when Symbol
                if value.key?(one_of_condition)
                  fully_matched_conditions += 1
                end
              when Array
                any_match = false
                full_match = true

                one_of_condition.each do |k|
                  if value.key?(k)
                    any_match = true
                  else
                    full_match = false
                  end
                end

                partial_match = !full_match && any_match

                if full_match
                  fully_matched_conditions += 1
                end

                if partial_match
                  partially_matched_conditions += 1
                end
              else
                raise ArgumentError, "Unknown one_of condition: #{one_of_condition.inspect}"
              end
            end
          end

          if fully_matched_conditions == 1 && partially_matched_conditions == 0
            nil # OK
          else
            @message || build_message(context)
          end
        end

        def build_message(context)
          argument_definitions = @validated.arguments(context).values
          required_names = @one_of.map do |arg_keyword|
            if arg_keyword.is_a?(Array)
              names = arg_keyword.map { |arg| arg_keyword_to_grapqhl_name(argument_definitions, arg) }
              "(" + names.join(" and ") + ")"
            else
              arg_keyword_to_grapqhl_name(argument_definitions, arg_keyword)
            end
          end

          if required_names.size == 1
            "%{validated} must include the following argument: #{required_names.first}."
          else
            "%{validated} must include exactly one of the following arguments: #{required_names.join(", ")}."
          end
        end

        def arg_keyword_to_grapqhl_name(argument_definitions, arg_keyword)
          argument_definition = argument_definitions.find { |defn| defn.keyword == arg_keyword }
          argument_definition.graphql_name
        end
      end
    end
  end
end
