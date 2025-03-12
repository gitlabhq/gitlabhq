# frozen_string_literal: true
module GraphQL
  # Raised automatically when a field's resolve function returns `nil`
  # for a non-null field.
  class InvalidNullError < GraphQL::Error
    # @return [GraphQL::BaseType] The owner of {#field}
    attr_reader :parent_type

    # @return [GraphQL::Field] The field which failed to return a value
    attr_reader :field

    # @return [nil, GraphQL::ExecutionError] The invalid value for this field
    attr_reader :value

    # @return [GraphQL::Language::Nodes::Field] the field where the error occurred
    attr_reader :ast_node

    def initialize(parent_type, field, value, ast_node)
      @parent_type = parent_type
      @field = field
      @value = value
      @ast_node = ast_node
      super("Cannot return null for non-nullable field #{@parent_type.graphql_name}.#{@field.graphql_name}")
    end

    class << self
      attr_accessor :parent_class

      def subclass_for(parent_class)
        subclass = Class.new(self)
        subclass.parent_class = parent_class
        subclass
      end

      def inspect
        if (name.nil? || parent_class&.name.nil?) && parent_class.respond_to?(:mutation) && (mutation = parent_class.mutation)
          "#{mutation.inspect}::#{parent_class.graphql_name}::InvalidNullError"
        else
          super
        end
      end
    end
  end
end
