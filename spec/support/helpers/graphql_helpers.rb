# frozen_string_literal: true

module GraphqlHelpers
  MutationDefinition = Struct.new(:query, :variables)

  NoData = Class.new(StandardError)
  UnauthorizedObject = Class.new(StandardError)

  def graphql_args(**values)
    ::Graphql::Arguments.new(values)
  end

  # makes an underscored string look like a fieldname
  # "merge_request" => "mergeRequest"
  def self.fieldnamerize(underscored_field_name)
    underscored_field_name.to_s.camelize(:lower)
  end

  # Run a loader's named resolver in a way that closely mimics the framework.
  #
  # First the `ready?` method is called. If it turns out that the resolver is not
  # ready, then the early return is returned instead.
  #
  # Then the resolve method is called.
  def resolve(resolver_class, args: {}, lookahead: :not_given, parent: :not_given, **resolver_args)
    args = aliased_args(resolver_class, args)
    args[:parent] = parent unless parent == :not_given
    args[:lookahead] = lookahead unless lookahead == :not_given
    resolver = resolver_instance(resolver_class, **resolver_args)
    ready, early_return = sync_all { resolver.ready?(**args) }

    return early_return unless ready

    resolver.resolve(**args)
  end

  # TODO: Remove this method entirely when GraphqlHelpers uses real resolve_field
  # see: https://gitlab.com/gitlab-org/gitlab/-/issues/287791
  def aliased_args(resolver, args)
    definitions = resolver.arguments

    args.transform_keys do |k|
      definitions[GraphqlHelpers.fieldnamerize(k)]&.keyword || k
    end
  end

  def resolver_instance(resolver_class, obj: nil, ctx: {}, field: nil, schema: GitlabSchema)
    if ctx.is_a?(Hash)
      q = double('Query', schema: schema)
      ctx = GraphQL::Query::Context.new(query: q, object: obj, values: ctx)
    end

    resolver_class.new(object: obj, context: ctx, field: field)
  end

  # Eagerly run a loader's named resolver
  # (syncs any lazy values returned by resolve)
  def eager_resolve(resolver_class, **opts)
    sync(resolve(resolver_class, **opts))
  end

  def sync(value)
    if GitlabSchema.lazy?(value)
      GitlabSchema.sync_lazy(value)
    else
      value
    end
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
    batch(max_queries: max_queries) { sync_all(&blk) }
  end

  def sync_all(&blk)
    lazy_vals = yield
    lazy_vals.is_a?(Array) ? lazy_vals.map { |val| sync(val) } : sync(lazy_vals)
  end

  def graphql_query_for(name, attributes = {}, fields = nil)
    <<~QUERY
    {
      #{query_graphql_field(name, attributes, fields)}
    }
    QUERY
  end

  def graphql_mutation(name, input, fields = nil, &block)
    raise ArgumentError, 'Please pass either `fields` parameter or a block to `#graphql_mutation`, but not both.' if fields.present? && block_given?

    mutation_name = GraphqlHelpers.fieldnamerize(name)
    input_variable_name = "$#{input_variable_name_for_mutation(name)}"
    mutation_field = GitlabSchema.mutation.fields[mutation_name]

    fields = yield if block_given?
    fields ||= all_graphql_fields_for(mutation_field.type.to_graphql)

    query = <<~MUTATION
      mutation(#{input_variable_name}: #{mutation_field.arguments['input'].type.to_graphql}) {
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

    { input_variable_name_for_mutation(name) => graphql_input }
  end

  def serialize_variables(variables)
    return unless variables
    return variables if variables.is_a?(String)

    ::Gitlab::Utils::MergeHash.merge(Array.wrap(variables).map(&:to_h)).to_json
  end

  def resolve_field(name, object, args = {}, current_user: nil)
    q = GraphQL::Query.new(GitlabSchema)
    context = GraphQL::Query::Context.new(query: q, object: object, values: { current_user: current_user })
    allow(context).to receive(:parent).and_return(nil)
    field = described_class.fields.fetch(GraphqlHelpers.fieldnamerize(name))
    instance = described_class.authorized_new(object, context)
    raise UnauthorizedObject unless instance

    field.resolve_field(instance, args, context)
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

  def field_with_params(name, attributes = {})
    namerized = GraphqlHelpers.fieldnamerize(name.to_s)
    return "#{namerized}" if attributes.blank?

    field_params = if attributes.is_a?(Hash)
                     "(#{attributes_to_graphql(attributes)})"
                   else
                     "(#{attributes})"
                   end

    "#{namerized}#{field_params}"
  end

  def query_graphql_field(name, attributes = {}, fields = nil)
    attributes, fields = [nil, attributes] if fields.nil? && !attributes.is_a?(Hash)

    field = field_with_params(name, attributes)

    field + wrap_fields(fields || all_graphql_fields_for(name.to_s.classify)).to_s
  end

  def page_info_selection
    "pageInfo { hasNextPage hasPreviousPage endCursor startCursor }"
  end

  def query_nodes(name, fields = nil, args: nil, of: name, include_pagination_info: false, max_depth: 1)
    fields ||= all_graphql_fields_for(of.to_s.classify, max_depth: max_depth)
    node_selection = include_pagination_info ? "#{page_info_selection} nodes" : :nodes
    query_graphql_path([[name, args], node_selection], fields)
  end

  # e.g:
  #   query_graphql_path(%i[foo bar baz], all_graphql_fields_for('Baz'))
  #   => foo { bar { baz { x y z } } }
  def query_graphql_path(segments, fields = nil)
    # we really want foldr here...
    segments.reverse.reduce(fields) do |tail, segment|
      name, args = Array.wrap(segment)
      query_graphql_field(name, args, tail)
    end
  end

  def wrap_fields(fields)
    fields = Array.wrap(fields).map do |field|
      case field
      when Symbol
        GraphqlHelpers.fieldnamerize(field)
      else
        field
      end
    end.join("\n")

    return unless fields.present?

    <<~FIELDS
    {
      #{fields}
    }
    FIELDS
  end

  def all_graphql_fields_for(class_name, parent_types = Set.new, max_depth: 3, excluded: [])
    # pulling _all_ fields can generate a _huge_ query (like complexity 180,000),
    # and significantly increase spec runtime. so limit the depth by default
    return if max_depth <= 0

    allow_unlimited_graphql_complexity
    allow_unlimited_graphql_depth
    allow_high_graphql_recursion
    allow_high_graphql_transaction_threshold

    type = GitlabSchema.types[class_name.to_s]
    return "" unless type

    # We can't guess arguments, so skip fields that require them
    skip = ->(name, field) { excluded.include?(name) || required_arguments?(field) }

    ::Graphql::FieldSelection.select_fields(type, skip, parent_types, max_depth)
  end

  def with_signature(variables, query)
    %Q[query(#{variables.map(&:sig).join(', ')}) #{query}]
  end

  def var(type)
    ::Graphql::Var.new(generate(:variable), type)
  end

  def attributes_to_graphql(arguments)
    ::Graphql::Arguments.new(arguments).to_s
  end

  def post_multiplex(queries, current_user: nil, headers: {})
    post api('/', current_user, version: 'graphql'), params: { _json: queries }, headers: headers
  end

  def post_graphql(query, current_user: nil, variables: nil, headers: {})
    params = { query: query, variables: serialize_variables(variables) }
    post api('/', current_user, version: 'graphql'), params: params, headers: headers
  end

  def post_graphql_mutation(mutation, current_user: nil)
    post_graphql(mutation.query, current_user: current_user, variables: mutation.variables)
  end

  def post_graphql_mutation_with_uploads(mutation, current_user: nil)
    file_paths = file_paths_in_mutation(mutation)
    params = mutation_to_apollo_uploads_param(mutation, files: file_paths)

    workhorse_post_with_file(api('/', current_user, version: 'graphql'),
                             params: params,
                             file_key: '1'
                            )
  end

  def file_paths_in_mutation(mutation)
    paths = []
    find_uploads(paths, [], mutation.variables)

    paths
  end

  # Depth first search for UploadedFile values
  def find_uploads(paths, path, value)
    case value
    when Rack::Test::UploadedFile
      paths << path
    when Hash
      value.each do |k, v|
        find_uploads(paths, path + [k], v)
      end
    when Array
      value.each_with_index do |v, i|
        find_uploads(paths, path + [i], v)
      end
    end
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

  def fresh_response_data
    Gitlab::Json.parse(response.body)
  end

  # Raises an error if no data is found
  def graphql_data(body = json_response)
    # Note that `json_response` is defined as `let(:json_response)` and
    # therefore, in a spec with multiple queries, will only contain data
    # from the _first_ query, not subsequent ones
    body['data'] || (raise NoData, graphql_errors(body))
  end

  def graphql_data_at(*path)
    graphql_dig_at(graphql_data, *path)
  end

  # Slightly more powerful than just `dig`:
  # - also supports implicit flat-mapping (.e.g. :foo :nodes :bar :nodes)
  def graphql_dig_at(data, *path)
    keys = path.map { |segment| segment.is_a?(Integer) ? segment : GraphqlHelpers.fieldnamerize(segment) }

    # Allows for array indexing, like this
    # ['project', 'boards', 'edges', 0, 'node', 'lists']
    keys.reduce(data) do |memo, key|
      if memo.is_a?(Array)
        key.is_a?(Integer) ? memo[key] : memo.flat_map { |e| Array.wrap(e[key]) }
      else
        memo&.dig(key)
      end
    end
  end

  # See note at graphql_data about memoization and multiple requests
  def graphql_errors(body = json_response)
    case body
    when Hash # regular query
      body['errors']
    when Array # multiplexed queries
      body.map { |response| response['errors'] }
    else
      raise "Unknown GraphQL response type #{body.class}"
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

  def scalar_fields_of(type_name)
    GitlabSchema.types[type_name].fields.map do |name, field|
      next if nested_fields?(field) || required_arguments?(field)

      name
    end.compact
  end

  def nested_fields_of(type_name)
    GitlabSchema.types[type_name].fields.map do |name, field|
      next if !nested_fields?(field) || required_arguments?(field)

      [name, field]
    end.compact
  end

  def nested_fields?(field)
    ::Graphql::FieldInspection.new(field).nested_fields?
  end

  def scalar?(field)
    ::Graphql::FieldInspection.new(field).scalar?
  end

  def enum?(field)
    ::Graphql::FieldInspection.new(field).enum?
  end

  # There are a few non BaseField fields in our schema (pageInfo for one).
  # None of them require arguments.
  def required_arguments?(field)
    return field.requires_argument? if field.is_a?(::Types::BaseField)

    if (meta = field.try(:metadata)) && meta[:type_class]
      required_arguments?(meta[:type_class])
    elsif args = field.try(:arguments)
      args.values.any? { |argument| argument.type.non_null? }
    else
      false
    end
  end

  def io_value?(value)
    Array.wrap(value).any? { |v| v.respond_to?(:to_io) }
  end

  def field_type(field)
    ::Graphql::FieldInspection.new(field).type
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

  def allow_high_graphql_transaction_threshold
    stub_const("Gitlab::QueryLimiting::Transaction::THRESHOLD", 1000)
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

  def type_factory
    Class.new(Types::BaseObject) do
      graphql_name 'TestType'

      field :name, GraphQL::STRING_TYPE, null: true

      yield(self) if block_given?
    end
  end

  def query_factory
    Class.new(Types::BaseObject) do
      graphql_name 'TestQuery'

      yield(self) if block_given?
    end
  end

  def execute_query(query_type)
    schema = Class.new(GraphQL::Schema) do
      use GraphQL::Pagination::Connections
      use Gitlab::Graphql::Authorize
      use Gitlab::Graphql::Pagination::Connections

      lazy_resolve ::Gitlab::Graphql::Lazy, :force

      query(query_type)
    end

    schema.execute(
      query_string,
      context: { current_user: user },
      variables: {}
    )
  end

  # A lookahead that selects everything
  def positive_lookahead
    double(selects?: true).tap do |selection|
      allow(selection).to receive(:selection).and_return(selection)
    end
  end

  # A lookahead that selects nothing
  def negative_lookahead
    double(selects?: false).tap do |selection|
      allow(selection).to receive(:selection).and_return(selection)
    end
  end
end

# This warms our schema, doing this as part of loading the helpers to avoid
# duplicate loading error when Rails tries autoload the types.
GitlabSchema.graphql_definition
