# frozen_string_literal: true

module GraphQL
  # Raised when a argument is configured with `loads:` and the client provides an `ID`,
  # but no object is loaded for that ID.
  #
  # @see GraphQL::Schema::Member::HasArguments::ArgumentObjectLoader#load_application_object_failed, A hook which you can override in resolvers, mutations and input objects.
  class LoadApplicationObjectFailedError < GraphQL::ExecutionError
    # @return [GraphQL::Schema::Argument] the argument definition for the argument that was looked up
    attr_reader :argument
    # @return [String] The ID provided by the client
    attr_reader :id
    # @return [Object] The value found with this ID
    attr_reader :object
    # @return [GraphQL::Query::Context]
    attr_reader :context

    def initialize(argument:, id:, object:, context:)
      @id = id
      @argument = argument
      @object = object
      @context = context
      super("No object found for `#{argument.graphql_name}: #{id.inspect}`")
    end
  end
end
