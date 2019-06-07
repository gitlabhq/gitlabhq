module GraphqlHelpers
  MutationDefinition = Struct.new(:query, :variables)

  # makes an underscored string look like a fieldname
  # "merge_request" => "mergeRequest"
  def self.fieldnamerize(underscored_field_name)
    graphql_field_name = underscored_field_name.to_s.camelize
    graphql_field_name[0] = graphql_field_name[0].downcase

    graphql_field_name
  end

  # Run a loader's named resolver
  def resolve(resolver_class, obj: nil, args: {}, ctx: {})
    resolver_class.new(object: obj, context: ctx).resolve(args)
  end

  # Runs a block inside a BatchLoader::Executor wrapper
  def batch(max_queries: nil, &blk)
    wrapper = proc do
      BatchLoader::Executor.ensure_current
      yield
    ensure
      BatchLoader::Executor.clear_current
    end

    if max_queries
      result = nil
      expect { result = wrapper.call }.not_to exceed_query_limit(max_queries)
      result
    else
      wrapper.call
    end
  end

  def graphql_query_for(name, attributes = {}, fields = nil)
    <<~QUERY
    {
      #{query_graphql_field(name, attributes, fields)}
    }
    QUERY
  end

  def graphql_mutation(name, input, fields = nil)
    mutation_name = GraphqlHelpers.fieldnamerize(name)
    input_variable_name = "$#{input_variable_name_for_mutation(name)}"
    mutation_field = GitlabSchema.mutation.fields[mutation_name]
    fields ||= all_graphql_fields_for(mutation_field.type)

    query = <<~MUTATION
      mutation(#{input_variable_name}: #{mutation_field.arguments['input'].type}) {
        #{mutation_name}(input: #{input_variable_name}) {
          #{fields}
        }
      }
    MUTATION
    variables = variables_for_mutation(name, input)

    MutationDefinition.new(query, variables)
  end

  def variables_for_mutation(name, input)
    graphql_input = input.map { |name, value| [GraphqlHelpers.fieldnamerize(name), value] }.to_h
    result = { input_variable_name_for_mutation(name) => graphql_input }

    # Avoid trying to serialize multipart data into JSON
    if graphql_input.values.none? { |value| io_value?(value) }
      result.to_json
    else
      result
    end
  end

  def input_variable_name_for_mutation(mutation_name)
    mutation_name = GraphqlHelpers.fieldnamerize(mutation_name)
    mutation_field = GitlabSchema.mutation.fields[mutation_name]
    input_type = field_type(mutation_field.arguments['input'])

    GraphqlHelpers.fieldnamerize(input_type)
  end

  def query_graphql_field(name, attributes = {}, fields = nil)
    fields ||= all_graphql_fields_for(name.classify)
    attributes = attributes_to_graphql(attributes)
    attributes = "(#{attributes})" if attributes.present?
    <<~QUERY
      #{name}#{attributes}
      #{wrap_fields(fields)}
    QUERY
  end

  def wrap_fields(fields)
    fields = Array.wrap(fields).join("\n")
    return unless fields.present?

    <<~FIELDS
    {
      #{fields}
    }
    FIELDS
  end

  def all_graphql_fields_for(class_name, parent_types = Set.new)
    allow_unlimited_graphql_complexity
    allow_unlimited_graphql_depth

    type = GitlabSchema.types[class_name.to_s]
    return "" unless type

    type.fields.map do |name, field|
      # We can't guess arguments, so skip fields that require them
      next if required_arguments?(field)

      singular_field_type = field_type(field)

      # If field type is the same as parent type, then we're hitting into
      # mutual dependency. Break it from infinite recursion
      next if parent_types.include?(singular_field_type)

      if nested_fields?(field)
        fields =
          all_graphql_fields_for(singular_field_type, parent_types | [type])

        "#{name} { #{fields} }"
      else
        name
      end
    end.compact.join("\n")
  end

  def attributes_to_graphql(attributes)
    attributes.map do |name, value|
      "#{GraphqlHelpers.fieldnamerize(name.to_s)}: \"#{value}\""
    end.join(", ")
  end

  def post_multiplex(queries, current_user: nil, headers: {})
    post api('/', current_user, version: 'graphql'), params: { _json: queries }, headers: headers
  end

  def post_graphql(query, current_user: nil, variables: nil, headers: {})
    post api('/', current_user, version: 'graphql'), params: { query: query, variables: variables }, headers: headers
  end

  def post_graphql_mutation(mutation, current_user: nil)
    post_graphql(mutation.query, current_user: current_user, variables: mutation.variables)
  end

  def graphql_data
    json_response['data']
  end

  def graphql_errors
    case json_response
    when Hash # regular query
      json_response['errors']
    when Array # multiplexed queries
      json_response.map { |response| response['errors'] }
    else
      raise "Unkown GraphQL response type #{json_response.class}"
    end
  end

  def graphql_mutation_response(mutation_name)
    graphql_data[GraphqlHelpers.fieldnamerize(mutation_name)]
  end

  def nested_fields?(field)
    !scalar?(field) && !enum?(field)
  end

  def scalar?(field)
    field_type(field).kind.scalar?
  end

  def enum?(field)
    field_type(field).kind.enum?
  end

  def required_arguments?(field)
    field.arguments.values.any? { |argument| argument.type.non_null? }
  end

  def io_value?(value)
    Array.wrap(value).any? { |v| v.respond_to?(:to_io) }
  end

  def field_type(field)
    field_type = field.type

    # The type could be nested. For example `[GraphQL::STRING_TYPE]`:
    # - List
    # - String!
    # - String
    field_type = field_type.of_type while field_type.respond_to?(:of_type)

    field_type
  end

  # for most tests, we want to allow unlimited complexity
  def allow_unlimited_graphql_complexity
    allow_any_instance_of(GitlabSchema).to receive(:max_complexity).and_return nil
    allow(GitlabSchema).to receive(:max_query_complexity).with(any_args).and_return nil
  end

  def allow_unlimited_graphql_depth
    allow_any_instance_of(GitlabSchema).to receive(:max_depth).and_return nil
    allow(GitlabSchema).to receive(:max_query_depth).with(any_args).and_return nil
  end
end

# This warms our schema, doing this as part of loading the helpers to avoid
# duplicate loading error when Rails tries autoload the types.
GitlabSchema.graphql_definition
