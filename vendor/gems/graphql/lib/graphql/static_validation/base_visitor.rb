# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class BaseVisitor < GraphQL::Language::StaticVisitor
      def initialize(document, context)
        @path = []
        @object_types = []
        @directives = []
        @field_definitions = []
        @argument_definitions = []
        @directive_definitions = []
        @context = context
        @types = context.query.types
        @schema = context.schema
        super(document)
      end

      attr_reader :context

      # @return [Array<GraphQL::ObjectType>] Types whose scope we've entered
      attr_reader :object_types

      # @return [Array<String>] The nesting of the current position in the AST
      def path
        @path.dup
      end

      # Build a class to visit the AST and perform validation,
      # or use a pre-built class if rules is `ALL_RULES` or empty.
      # @param rules [Array<Module, Class>]
      # @return [Class] A class for validating `rules` during visitation
      def self.including_rules(rules)
        if rules.empty?
          # It's not doing _anything?!?_
          BaseVisitor
        elsif rules == ALL_RULES
          InterpreterVisitor
        else
          visitor_class = Class.new(self) do
            include(GraphQL::StaticValidation::DefinitionDependencies)
          end

          rules.reverse_each do |r|
            # If it's a class, it gets attached later.
            if !r.is_a?(Class)
              visitor_class.include(r)
            end
          end

          visitor_class.include(ContextMethods)
          visitor_class
        end
      end

      module ContextMethods
        def on_operation_definition(node, parent)
          object_type = @schema.root_type_for_operation(node.operation_type)
          push_type(object_type)
          @path.push("#{node.operation_type}#{node.name ? " #{node.name}" : ""}")
          super
          @object_types.pop
          @path.pop
        end

        def on_fragment_definition(node, parent)
          on_fragment_with_type(node) do
            @path.push("fragment #{node.name}")
            super
          end
        end

        def on_inline_fragment(node, parent)
          on_fragment_with_type(node) do
            @path.push("...#{node.type ? " on #{node.type.to_query_string}" : ""}")
            super
          end
        end

        def on_field(node, parent)
          parent_type = @object_types.last
          field_definition = @types.field(parent_type, node.name)
          @field_definitions.push(field_definition)
          if !field_definition.nil?
            next_object_type = field_definition.type.unwrap
            push_type(next_object_type)
          else
            push_type(nil)
          end
          @path.push(node.alias || node.name)
          super
          @field_definitions.pop
          @object_types.pop
          @path.pop
        end

        def on_directive(node, parent)
          directive_defn = @context.schema_directives[node.name]
          @directive_definitions.push(directive_defn)
          super
          @directive_definitions.pop
        end

        def on_argument(node, parent)
          argument_defn = if (arg = @argument_definitions.last)
            arg_type = arg.type.unwrap
            if arg_type.kind.input_object?
              @types.argument(arg_type, node.name)
            else
              nil
            end
          elsif (directive_defn = @directive_definitions.last)
            @types.argument(directive_defn, node.name)
          elsif (field_defn = @field_definitions.last)
            @types.argument(field_defn, node.name)
          else
            nil
          end

          @argument_definitions.push(argument_defn)
          @path.push(node.name)
          super
          @argument_definitions.pop
          @path.pop
        end

        def on_fragment_spread(node, parent)
          @path.push("... #{node.name}")
          super
          @path.pop
        end

        def on_input_object(node, parent)
          arg_defn = @argument_definitions.last
          if arg_defn && arg_defn.type.list?
            @path.push(parent.children.index(node))
            super
            @path.pop
          else
            super
          end
        end

        # @return [GraphQL::BaseType] The current object type
        def type_definition
          @object_types.last
        end

        # @return [GraphQL::BaseType] The type which the current type came from
        def parent_type_definition
          @object_types[-2]
        end

        # @return [GraphQL::Field, nil] The most-recently-entered GraphQL::Field, if currently inside one
        def field_definition
          @field_definitions.last
        end

        # @return [GraphQL::Directive, nil] The most-recently-entered GraphQL::Directive, if currently inside one
        def directive_definition
          @directive_definitions.last
        end

        # @return [GraphQL::Argument, nil] The most-recently-entered GraphQL::Argument, if currently inside one
        def argument_definition
          # Don't get the _last_ one because that's the current one.
          # Get the second-to-last one, which is the parent of the current one.
          @argument_definitions[-2]
        end

        private

        def on_fragment_with_type(node)
          object_type = if node.type
            @types.type(node.type.name)
          else
            @object_types.last
          end
          push_type(object_type)
          yield(node)
          @object_types.pop
          @path.pop
        end

        def push_type(t)
          @object_types.push(t)
        end
      end

      private

      def add_error(error, path: nil)
        if @context.too_many_errors?
          throw :too_many_validation_errors
        end
        error.path ||= (path || @path.dup)
        context.errors << error
      end

    end
  end
end
