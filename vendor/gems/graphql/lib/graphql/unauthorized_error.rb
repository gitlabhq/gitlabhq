# frozen_string_literal: true
module GraphQL
  # When an `authorized?` hook returns false, this error is used to communicate the failure.
  # It's passed to {Schema.unauthorized_object}.
  #
  # Alternatively, custom code in `authorized?` may raise this error. It will be routed the same way.
  class UnauthorizedError < GraphQL::Error
    # @return [Object] the application object that failed the authorization check
    attr_reader :object

    # @return [Class] the GraphQL object type whose `.authorized?` method was called (and returned false)
    attr_reader :type

    # @return [GraphQL::Query::Context] the context for the current query
    attr_accessor :context

    def initialize(message = nil, object: nil, type: nil, context: nil)
      if message.nil? && object.nil? && type.nil?
        raise ArgumentError, "#{self.class.name} requires either a message or keywords"
      end

      @object = object
      @type = type
      @context = context
      message ||= "An instance of #{object.class} failed #{type.graphql_name}'s authorization check"
      super(message)
    end
  end
end
