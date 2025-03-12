# frozen_string_literal: true

module GraphQL
  class Schema
    class Field
      class ConnectionExtension < GraphQL::Schema::FieldExtension
        def apply
          field.argument :after, "String", "Returns the elements in the list that come after the specified cursor.", required: false
          field.argument :before, "String", "Returns the elements in the list that come before the specified cursor.", required: false
          field.argument :first, "Int", "Returns the first _n_ elements from the list.", required: false
          field.argument :last, "Int", "Returns the last _n_ elements from the list.", required: false
        end

        # Remove pagination args before passing it to a user method
        def resolve(object:, arguments:, context:)
          next_args = arguments.dup
          next_args.delete(:first)
          next_args.delete(:last)
          next_args.delete(:before)
          next_args.delete(:after)
          yield(object, next_args, arguments)
        end

        def after_resolve(value:, object:, arguments:, context:, memo:)
          original_arguments = memo
          # rename some inputs to avoid conflicts inside the block
          maybe_lazy = value
          value = nil
          context.query.after_lazy(maybe_lazy) do |resolved_value|
            value = resolved_value
            if value.is_a? GraphQL::ExecutionError
              # This isn't even going to work because context doesn't have ast_node anymore
              context.add_error(value)
              nil
            elsif value.nil?
              nil
            elsif value.is_a?(GraphQL::Pagination::Connection)
              # update the connection with some things that may not have been provided
              value.context ||= context
              value.parent ||= object.object
              value.first_value ||= original_arguments[:first]
              value.after_value ||= original_arguments[:after]
              value.last_value ||= original_arguments[:last]
              value.before_value ||= original_arguments[:before]
              value.arguments ||= original_arguments # rubocop:disable Development/ContextIsPassedCop -- unrelated .arguments method
              value.field ||= field
              if field.has_max_page_size? && !value.has_max_page_size_override?
                value.max_page_size = field.max_page_size
              end
              if field.has_default_page_size? && !value.has_default_page_size_override?
                value.default_page_size = field.default_page_size
              end
              if (custom_t = context.schema.connections.edge_class_for_field(@field))
                value.edge_class = custom_t
              end
              value
            else
              context.namespace(:connections)[:all_wrappers] ||= context.schema.connections.all_wrappers
              context.schema.connections.wrap(field, object.object, value, original_arguments, context)
            end
          end
        end
      end
    end
  end
end
