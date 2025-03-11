# frozen_string_literal: true
module GraphQL
  # Error raised when the value provided for a field
  # can't be resolved to one of the possible types for the field.
  class UnresolvedTypeError < GraphQL::RuntimeTypeError
    # @return [Object] The runtime value which couldn't be successfully resolved with `resolve_type`
    attr_reader :value

    # @return [GraphQL::Field] The field whose value couldn't be resolved (`field.type` is type which couldn't be resolved)
    attr_reader :field

    # @return [GraphQL::BaseType] The owner of `field`
    attr_reader :parent_type

    # @return [Object] The return of {Schema#resolve_type} for `value`
    attr_reader :resolved_type

    # @return [Array<GraphQL::BaseType>] The allowed options for resolving `value` to `field.type`
    attr_reader :possible_types

    def initialize(value, field, parent_type, resolved_type, possible_types)
      @value = value
      @field = field
      @parent_type = parent_type
      @resolved_type = resolved_type
      @possible_types = possible_types
      message = "The value from \"#{field.graphql_name}\" on \"#{parent_type.graphql_name}\" could not be resolved to \"#{field.type.to_type_signature}\". " \
        "(Received: `#{resolved_type.inspect}`, Expected: [#{possible_types.map(&:graphql_name).join(", ")}]) " \
        "Make sure you have defined a `resolve_type` proc on your schema and that value `#{value.inspect}` " \
        "gets resolved to a valid type. You may need to add your type to `orphan_types` if it implements an " \
        "interface but isn't a return type of any other field."
      super(message)
    end
  end
end
