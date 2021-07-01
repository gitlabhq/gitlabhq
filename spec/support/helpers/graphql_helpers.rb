# frozen_string_literal: true

module GraphqlHelpers
  def self.included(base)
    base.include(::Gitlab::Graphql::Laziness)
  end

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

  def self.deep_fieldnamerize(map)
    map.to_h do |k, v|
      [fieldnamerize(k), v.is_a?(Hash) ? deep_fieldnamerize(v) : v]
    end
  end

  # Run this resolver exactly as it would be called in the framework. This
  # includes all authorization hooks, all argument processing and all result
  # wrapping.
  # see: GraphqlHelpers#resolve_field
  def resolve(
    resolver_class, # [Class[<= BaseResolver]] The resolver at test.
    obj: nil, # [Any] The BaseObject#object for the resolver (available as `#object` in the resolver).
    args: {}, # [Hash] The arguments to the resolver (using client names).
    ctx: {},  # [#to_h] The current context values.
    schema: GitlabSchema, # [GraphQL::Schema] Schema to use during execution.
    parent: :not_given, # A GraphQL query node to be passed as the `:parent` extra.
    lookahead: :not_given # A GraphQL lookahead object to be passed as the `:lookahead` extra.
  )
    # All resolution goes through fields, so we need to create one here that
    # uses our resolver. Thankfully, apart from the field name, resolvers
    # contain all the configuration needed to define one.
    field_options = resolver_class.field_options.merge(
      owner: resolver_parent,
      name: 'field_value'
    )
    field = ::Types::BaseField.new(**field_options)

    # All mutations accept a single `:input` argument. Wrap arguments here.
    # See the unwrapping below in GraphqlHelpers#resolve_field
    args = { input: args } if resolver_class <= ::Mutations::BaseMutation && !args.key?(:input)

    resolve_field(field, obj,
                  args: args,
                  ctx: ctx,
                  schema: schema,
                  object_type: resolver_parent,
                  extras: { parent: parent, lookahead: lookahead })
  end

  # Resolve the value of a field on an object.
  #
  # Use this method to test individual fields within type specs.
  #
  # e.g.
  #
  #   issue = create(:issue)
  #   user = issue.author
  #   project = issue.project
  #
  #   resolve_field(:author, issue, current_user: user, object_type: ::Types::IssueType)
  #   resolve_field(:issue, project, args: { iid: issue.iid }, current_user: user, object_type: ::Types::ProjectType)
  #
  # The `object_type` defaults to the `described_class`, so when called from type specs,
  # the above can be written as:
  #
  #   # In project_type_spec.rb
  #   resolve_field(:author, issue, current_user: user)
  #
  #   # In issue_type_spec.rb
  #   resolve_field(:issue, project, args: { iid: issue.iid }, current_user: user)
  #
  # NB: Arguments are passed from the client's perspective. If there is an argument
  # `foo` aliased as `bar`, then we would pass `args: { bar: the_value }`, and
  # types are checked before resolution.
  def resolve_field(
    field,                       # An instance of `BaseField`, or the name of a field on the current described_class
    object,                      # The current object of the `BaseObject` this field 'belongs' to
    args:   {},                  # Field arguments (keys will be fieldnamerized)
    ctx:    {},                  # Context values (important ones are :current_user)
    extras: {},                  # Stub values for field extras (parent and lookahead)
    current_user: :not_given,    # The current user (specified explicitly, overrides ctx[:current_user])
    schema: GitlabSchema,        # A specific schema instance
    object_type: described_class # The `BaseObject` type this field belongs to
  )
    field = to_base_field(field, object_type)
    ctx[:current_user] = current_user unless current_user == :not_given
    query = GraphQL::Query.new(schema, context: ctx.to_h)
    extras[:lookahead] = negative_lookahead if extras[:lookahead] == :not_given && field.extras.include?(:lookahead)

    query_ctx = query.context

    mock_extras(query_ctx, **extras)

    parent = object_type.authorized_new(object, query_ctx)
    raise UnauthorizedObject unless parent

    # TODO: This will need to change when we move to the interpreter:
    # At that point, arguments will be a plain ruby hash rather than
    # an Arguments object
    # see: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27536
    #      https://gitlab.com/gitlab-org/gitlab/-/issues/210556
    arguments = field.to_graphql.arguments_class.new(
      GraphqlHelpers.deep_fieldnamerize(args),
      context: query_ctx,
      defaults_used: []
    )

    # we enable the request store so we can track gitaly calls.
    ::Gitlab::WithRequestStore.with_request_store do
      # TODO: This will need to change when we move to the interpreter - at that
      # point we will call `field#resolve`

      # Unwrap the arguments to mutations. This pairs with the wrapping in GraphqlHelpers#resolve
      # If arguments are not wrapped first, then arguments processing will raise.
      # If arguments are not unwrapped here, then the resolve method of the mutation will raise argument errors.
      arguments = arguments.to_kwargs[:input] if field.resolver && field.resolver <= ::Mutations::BaseMutation

      field.resolve_field(parent, arguments, query_ctx)
    end
  end

  def mock_extras(context, parent: :not_given, lookahead: :not_given)
    allow(context).to receive(:parent).and_return(parent) unless parent == :not_given
    allow(context).to receive(:lookahead).and_return(lookahead) unless lookahead == :not_given
  end

  # a synthetic BaseObject type to be used in resolver specs. See `GraphqlHelpers#resolve`
  def resolver_parent
    @resolver_parent ||= fresh_object_type('ResolverParent')
  end

  def fresh_object_type(name = 'Object')
    Class.new(::Types::BaseObject) { graphql_name name }
  end

  def resolver_instance(resolver_class, obj: nil, ctx: {}, field: nil, schema: GitlabSchema, subscription_update: false)
    if ctx.is_a?(Hash)
      q = double('Query', schema: schema, subscription_update?: subscription_update)
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

  def with_clean_batchloader_executor(&block)
    BatchLoader::Executor.ensure_current
    yield
  ensure
    BatchLoader::Executor.clear_current
  end

  # Runs a block inside a BatchLoader::Executor wrapper
  def batch(max_queries: nil, &blk)
    wrapper = -> { with_clean_batchloader_executor(&blk) }

    if max_queries
      result = nil
      expect { result = wrapper.call }.not_to exceed_query_limit(max_queries)
      result
    else
      wrapper.call
    end
  end

  # Use this when writing N+1 tests.
  #
  # It does not use the controller, so it avoids confounding factors due to
  # authentication (token set-up, license checks)
  # It clears the request store, rails cache, and BatchLoader Executor between runs.
  def run_with_clean_state(query, **args)
    ::Gitlab::WithRequestStore.with_request_store do
      with_clean_rails_cache do
        with_clean_batchloader_executor do
          ::GitlabSchema.execute(query, **args)
        end
      end
    end
  end

  # Basically a combination of use_sql_query_cache and use_clean_rails_memory_store_caching,
  # but more fine-grained, suitable for comparing two runs in the same example.
  def with_clean_rails_cache(&blk)
    caching_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    ActiveRecord::Base.cache(&blk)
  ensure
    Rails.cache = caching_store
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

  def graphql_query_for(name, args = {}, selection = nil, operation_name = nil)
    type = GitlabSchema.types['Query'].fields[GraphqlHelpers.fieldnamerize(name)]&.type
    query = wrap_query(query_graphql_field(name, args, selection, type))
    query = "query #{operation_name}#{query}" if operation_name

    query
  end

  def wrap_query(query)
    q = query.to_s
    return q if q.starts_with?('{')

    "{ #{q} }"
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

  # Recursively convert a Hash with Ruby-style keys to GraphQL fieldname-style keys
  #
  # prepare_input_for_mutation({ 'my_key' => 1 })
  #   => { 'myKey' => 1}
  def prepare_input_for_mutation(input)
    input.to_h do |name, value|
      value = prepare_input_for_mutation(value) if value.is_a?(Hash)

      [GraphqlHelpers.fieldnamerize(name), value]
    end
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

  def query_graphql_field(name, attributes = {}, fields = nil, type = nil)
    type ||= name.to_s.classify
    if fields.nil? && !attributes.is_a?(Hash)
      fields = attributes
      attributes = nil
    end

    field = field_with_params(name, attributes)

    field + wrap_fields(fields || all_graphql_fields_for(type)).to_s
  end

  def page_info_selection
    "pageInfo { hasNextPage hasPreviousPage endCursor startCursor }"
  end

  def query_nodes(name, fields = nil, args: nil, of: name, include_pagination_info: false, max_depth: 1)
    fields ||= all_graphql_fields_for(of.to_s.classify, max_depth: max_depth)
    node_selection = include_pagination_info ? "#{page_info_selection} nodes" : :nodes
    query_graphql_path([[name, args], node_selection], fields)
  end

  def query_graphql_fragment(name)
    "... on #{name} { #{all_graphql_fields_for(name)} }"
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
    allow_unlimited_graphql_depth if max_depth > 1
    allow_high_graphql_recursion
    allow_high_graphql_transaction_threshold

    type = class_name.respond_to?(:kind) ? class_name : GitlabSchema.types[class_name.to_s]
    raise "#{class_name} is not a known type in the GitlabSchema" unless type

    # We can't guess arguments, so skip fields that require them
    skip = ->(name, field) { excluded.include?(name) || required_arguments?(field) }

    ::Graphql::FieldSelection.select_fields(type, skip, parent_types, max_depth)
  end

  def with_signature(variables, query)
    %Q[query(#{variables.map(&:sig).join(', ')}) #{wrap_query(query)}]
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

  def get_multiplex(queries, current_user: nil, headers: {})
    path = "/?#{queries.to_query('_json')}"
    get api(path, current_user, version: 'graphql'), headers: headers
  end

  def post_graphql(query, current_user: nil, variables: nil, headers: {}, token: {}, params: {})
    params = params.merge(query: query, variables: serialize_variables(variables))
    post api('/', current_user, version: 'graphql', **token), params: params, headers: headers

    return unless graphql_errors

    # Errors are acceptable, but not this one:
    expect(graphql_errors).not_to include(a_hash_including('message' => 'Internal server error'))
  end

  def get_graphql(query, current_user: nil, variables: nil, headers: {}, token: {}, params: {})
    vars = "variables=#{CGI.escape(serialize_variables(variables))}" if variables
    params = params.to_a.map { |k, v| v.to_query(k) }
    path = ["/?query=#{CGI.escape(query)}", vars, *params].join('&')
    get api(path, current_user, version: 'graphql', **token), headers: headers

    return unless graphql_errors

    # Errors are acceptable, but not this one:
    expect(graphql_errors).not_to include(a_hash_including('message' => 'Internal server error'))
  end

  def post_graphql_mutation(mutation, current_user: nil, token: {})
    post_graphql(mutation.query,
                 current_user: current_user,
                 variables: mutation.variables,
                 token: token)
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
  # NB: We use fresh_response_data to support tests that make multiple requests.
  def graphql_data(body = fresh_response_data)
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

  def global_id_of(model, id: nil, model_name: nil)
    if id || model_name
      ::Gitlab::GlobalId.build(model, id: id, model_name: model_name).to_s
    else
      model.to_global_id.to_s
    end
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

  # assumes query_string to be let-bound in the current context
  def execute_query(query_type, schema: empty_schema, graphql: query_string)
    schema.query(query_type)

    schema.execute(
      graphql,
      context: { current_user: user },
      variables: {}
    )
  end

  def empty_schema
    Class.new(GraphQL::Schema) do
      use GraphQL::Pagination::Connections
      use Gitlab::Graphql::Pagination::Connections

      lazy_resolve ::Gitlab::Graphql::Lazy, :force
    end
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

  private

  def to_base_field(name_or_field, object_type)
    case name_or_field
    when ::Types::BaseField
      name_or_field
    else
      field_by_name(name_or_field, object_type)
    end
  end

  def field_by_name(name, object_type)
    name = ::GraphqlHelpers.fieldnamerize(name)

    object_type.fields[name] || (raise ArgumentError, "Unknown field #{name} for #{described_class.graphql_name}")
  end
end

# This warms our schema, doing this as part of loading the helpers to avoid
# duplicate loading error when Rails tries autoload the types.
GitlabSchema.graphql_definition
