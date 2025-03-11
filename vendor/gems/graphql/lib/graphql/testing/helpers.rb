# frozen_string_literal: true
module GraphQL
  module Testing
    module Helpers
      # @param schema_class [Class<GraphQL::Schema>]
      # @return [Module] A helpers module which always uses the given schema
      def self.for(schema_class)
        SchemaHelpers.for(schema_class)
      end

      class Error < GraphQL::Error
      end

      class TypeNotVisibleError < Error
        def initialize(type_name:)
          message = "`#{type_name}` should be `visible?` this field resolution and `context`, but it was not"
          super(message)
        end
      end

      class FieldNotVisibleError < Error
        def initialize(type_name:, field_name:)
          message = "`#{type_name}.#{field_name}` should be `visible?` for this resolution, but it was not"
          super(message)
        end
      end

      class TypeNotDefinedError < Error
        def initialize(type_name:)
          message = "No type named `#{type_name}` is defined; choose another type name or define this type."
          super(message)
        end
      end

      class FieldNotDefinedError < Error
        def initialize(type_name:, field_name:)
          message = "`#{type_name}` has no field named `#{field_name}`; pick another name or define this field."
          super(message)
        end
      end

      def run_graphql_field(schema, field_path, object, arguments: {}, context: {}, ast_node: nil, lookahead: nil)
        type_name, *field_names = field_path.split(".")
        dummy_query = GraphQL::Query.new(schema, "{ __typename }", context: context)
        query_context = dummy_query.context
        object_type = dummy_query.types.type(type_name) # rubocop:disable Development/ContextIsPassedCop
        if object_type
          graphql_result = object
          field_names.each do |field_name|
            inner_object = graphql_result
            graphql_result = object_type.wrap(inner_object, query_context)
            if graphql_result.nil?
              return nil
            end
            visible_field = dummy_query.types.field(object_type, field_name) # rubocop:disable Development/ContextIsPassedCop
            if visible_field
              dummy_query.context.dataloader.run_isolated {
                query_context[:current_field] = visible_field
                field_args = visible_field.coerce_arguments(graphql_result, arguments, query_context)
                field_args = schema.sync_lazy(field_args)
                if !visible_field.extras.empty?
                  extra_args = {}
                  visible_field.extras.each do |extra|
                    extra_args[extra] = case extra
                    when :ast_node
                      ast_node ||= GraphQL::Language::Nodes::Field.new(name: visible_field.graphql_name)
                    when :lookahead
                      lookahead ||= begin
                        ast_node ||= GraphQL::Language::Nodes::Field.new(name: visible_field.graphql_name)
                        Execution::Lookahead.new(
                          query: dummy_query,
                          ast_nodes: [ast_node],
                          field: visible_field,
                        )
                      end
                    else
                      raise ArgumentError, "This extra isn't supported in `run_graphql_field` yet: `#{extra.inspect}`. Open an issue on GitHub to request it: https://github.com/rmosolgo/graphql-ruby/issues/new"
                    end
                  end

                  field_args = field_args.merge_extras(extra_args)
                end
                graphql_result = visible_field.resolve(graphql_result, field_args.keyword_arguments, query_context)
                graphql_result = schema.sync_lazy(graphql_result)
              }
              object_type = visible_field.type.unwrap
            elsif object_type.all_field_definitions.any? { |f| f.graphql_name == field_name }
              raise FieldNotVisibleError.new(field_name: field_name, type_name: type_name)
            else
              raise FieldNotDefinedError.new(type_name: type_name, field_name: field_name)
            end
          end
          graphql_result
        else
          unfiltered_type = schema.use_visibility_profile? ? schema.visibility.get_type(type_name) : schema.get_type(type_name) # rubocop:disable Development/ContextIsPassedCop
          if unfiltered_type
            raise TypeNotVisibleError.new(type_name: type_name)
          else
            raise TypeNotDefinedError.new(type_name: type_name)
          end
        end
      end

      def with_resolution_context(schema, type:, object:, context:{})
        resolution_context = ResolutionAssertionContext.new(
          self,
          schema: schema,
          type_name: type,
          object: object,
          context: context
        )
        yield(resolution_context)
      end

      class ResolutionAssertionContext
        def initialize(test, type_name:, object:, schema:, context:)
          @test = test
          @type_name = type_name
          @object = object
          @schema = schema
          @context = context
        end


        def run_graphql_field(field_name, arguments: {})
          if @schema
            @test.run_graphql_field(@schema, "#{@type_name}.#{field_name}", @object, arguments: arguments, context: @context)
          else
            @test.run_graphql_field("#{@type_name}.#{field_name}", @object, arguments: arguments, context: @context)
          end
        end
      end

      module SchemaHelpers
        include Helpers

        def run_graphql_field(field_path, object, arguments: {}, context: {})
          super(@@schema_class_for_helpers, field_path, object, arguments: arguments, context: context)
        end

        def with_resolution_context(*args, **kwargs, &block)
          # schema will be added later
          super(nil, *args, **kwargs, &block)
        end

        def self.for(schema_class)
          Module.new do
            include SchemaHelpers
            @@schema_class_for_helpers = schema_class
          end
        end
      end
    end
  end
end
