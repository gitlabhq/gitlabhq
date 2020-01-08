# frozen_string_literal: true

module GraphqlHelpers
  MutationDefinition = Struct.new(:query, :variables)

  NoData = Class.new(StandardError)

  # makes an underscored string look like a fieldname
  # "merge_request" => "mergeRequest"
  def self.fieldnamerize(underscored_field_name)
    underscored_field_name.to_s.camelize(:lower)
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

  # BatchLoader::GraphQL returns a wrapper, so we need to :sync in order
  # to get the actual values
  def batch_sync(max_queries: nil, &blk)
    wrapper = proc do
      lazy_vals = yield
      lazy_vals.is_a?(Array) ? lazy_vals.map(&:sync) : lazy_vals&.sync
    end

    batch(max_queries: max_queries, &wrapper)
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
    graphql_input = prepare_input_for_mutation(input)

    result = { input_variable_name_for_mutation(name) => graphql_input }

    # Avoid trying to serialize multipart data into JSON
    if graphql_input.values.none? { |value| io_value?(value) }
      result.to_json
    else
      result
    end
  end

  # Recursively convert a Hash with Ruby-style keys to GraphQL fieldname-style keys
  #
  # prepare_input_for_mutation({ 'my_key' => 1 })
  #   => { 'myKey' => 1}
  def prepare_input_for_mutation(input)
    input.map do |name, value|
      value = prepare_input_for_mutation(value) if value.is_a?(Hash)

      [GraphqlHelpers.fieldnamerize(name), value]
    end.to_h
  end

  def input_variable_name_for_mutation(mutation_name)
    mutation_name = GraphqlHelpers.fieldnamerize(mutation_name)
    mutation_field = GitlabSchema.mutation.fields[mutation_name]
    input_type = field_type(mutation_field.arguments['input'])

    GraphqlHelpers.fieldnamerize(input_type)
  end

  def query_graphql_field(name, attributes = {}, fields = nil)
    field_params = if attributes.present?
                     "(#{attributes_to_graphql(attributes)})"
                   else
                     ''
                   end

    <<~QUERY
      #{GraphqlHelpers.fieldnamerize(name.to_s)}#{field_params}
      #{wrap_fields(fields || all_graphql_fields_for(name.to_s.classify))}
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

  def all_graphql_fields_for(class_name, parent_types = Set.new, max_depth: 3)
    # pulling _all_ fields can generate a _huge_ query (like complexity 180,000),
    # and significantly increase spec runtime. so limit the depth by default
    return if max_depth <= 0

    allow_unlimited_graphql_complexity
    allow_unlimited_graphql_depth
    allow_high_graphql_recursion

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
          all_graphql_fields_for(singular_field_type, parent_types | [type], max_depth: max_depth - 1)

        "#{name} { #{fields} }" unless fields.blank?
      else
        name
      end
    end.compact.join("\n")
  end

  def attributes_to_graphql(attributes)
    attributes.map do |name, value|
      value_str = if value.is_a?(Array)
                    '["' + value.join('","') + '"]'
                  else
                    "\"#{value}\""
                  end

      "#{GraphqlHelpers.fieldnamerize(name.to_s)}: #{value_str}"
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

  # this implements GraphQL multipart request v2
  # https://github.com/jaydenseric/graphql-multipart-request-spec/tree/v2.0.0-alpha.2
  # this is simplified and do not support file deduplication
  def mutation_to_apollo_uploads_param(mutation, files: [])
    operations = { 'query' => mutation.query, 'variables' => mutation.variables }
    map = {}
    extracted_files = {}

    files.each_with_index do |file_path, idx|
      apollo_idx = (idx + 1).to_s
      parent_dig_path = file_path[0..-2]
      file_key = file_path[-1]

      parent = operations['variables']
      parent = parent.dig(*parent_dig_path) unless parent_dig_path.empty?

      extracted_files[apollo_idx] = parent[file_key]
      parent[file_key] = nil

      map[apollo_idx] = ["variables.#{file_path.join('.')}"]
    end

    { operations: operations.to_json, map: map.to_json }.merge(extracted_files)
  end

  # Raises an error if no data is found
  def graphql_data
    json_response['data'] || (raise NoData, graphql_errors)
  end

  def graphql_errors
    case json_response
    when Hash # regular query
      json_response['errors']
    when Array # multiplexed queries
      json_response.map { |response| response['errors'] }
    else
      raise "Unknown GraphQL response type #{json_response.class}"
    end
  end

  def expect_graphql_errors_to_include(regexes_to_match)
    raise "No errors. Was expecting to match #{regexes_to_match}" if graphql_errors.nil? || graphql_errors.empty?

    error_messages = flattened_errors.collect { |error_hash| error_hash["message"] }
    Array.wrap(regexes_to_match).flatten.each do |regex|
      expect(error_messages).to include a_string_matching regex
    end
  end

  def expect_graphql_errors_to_be_empty
    expect(flattened_errors).to be_empty
  end

  def flattened_errors
    Array.wrap(graphql_errors).flatten.compact
  end

  # Raises an error if no response is found
  def graphql_mutation_response(mutation_name)
    graphql_data.fetch(GraphqlHelpers.fieldnamerize(mutation_name))
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

  def allow_high_graphql_recursion
    allow_any_instance_of(Gitlab::Graphql::QueryAnalyzers::RecursionAnalyzer).to receive(:recursion_threshold).and_return 1000
  end

  def node_array(data, extract_attribute = nil)
    data.map do |item|
      extract_attribute ? item['node'][extract_attribute] : item['node']
    end
  end

  def global_id_of(model)
    model.to_global_id.to_s
  end

  def missing_required_argument(path, argument)
    a_hash_including(
      'path' => ['query'].concat(path),
      'extensions' => a_hash_including('code' => 'missingRequiredArguments', 'arguments' => argument.to_s)
    )
  end

  def custom_graphql_error(path, msg)
    a_hash_including('path' => path, 'message' => msg)
  end
end

# This warms our schema, doing this as part of loading the helpers to avoid
# duplicate loading error when Rails tries autoload the types.
GitlabSchema.graphql_definition
