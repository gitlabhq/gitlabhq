# frozen_string_literal: true

module GraphqlHelpers
  def self.included(base)
    base.include(::ApiHelpers)
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
    # Skip transformation for a field with leading underscore
    return underscored_field_name.to_s if underscored_field_name.start_with?('_')

    underscored_field_name.to_s.camelize(:lower)
  end

  def self.deep_fieldnamerize(map)
    map.to_h do |k, v|
      [fieldnamerize(k), v.is_a?(Hash) ? deep_fieldnamerize(v) : v]
    end
  end

  # Some arguments use `as:` to expose a different name internally.
  # Transform the args to use those names
  def self.deep_transform_args(args, field)
    args.to_h do |k, v|
      argument = field.arguments[k.to_s.camelize(:lower)]
      [argument.keyword, v.is_a?(Hash) ? deep_transform_args(v, argument.type) : v]
    end
  end

  # Convert incoming args into the form usually passed in from the client,
  # all strings, etc.
  def self.as_graphql_argument_literals(args)
    args.transform_values { |value| transform_arg_value(value) }
  end

  def self.transform_arg_value(value)
    case value
    when Hash
      as_graphql_argument_literals(value)
    when Array
      value.map { |x| transform_arg_value(x) }
    when Time, ActiveSupport::TimeWithZone
      value.strftime("%F %T.%N %z")
    when Date, GlobalID, Symbol
      value.to_s
    else
      value
    end
  end

  # Run this resolver exactly as it would be called in the framework. This
  # includes all authorization hooks, all argument processing and all result
  # wrapping.
  # see: GraphqlHelpers#resolve_field
  #
  # TODO: this is too coupled to gem internals, making upgrades incredibly
  #       painful, and bypasses much of the validation of the framework.
  #       See https://gitlab.com/gitlab-org/gitlab/-/issues/363121
  # rubocop: disable Metrics/ParameterLists -- This was disabled to add `field_opts`, needed for :calls_gitaly
  def resolve(
    resolver_class, # [Class[<= BaseResolver]] The resolver at test.
    obj: nil, # [Any] The BaseObject#object for the resolver (available as `#object` in the resolver).
    args: {}, # [Hash] The arguments to the resolver (using client names).
    ctx: {},  # [#to_h] The current context values.
    schema: GitlabSchema, # [GraphQL::Schema] Schema to use during execution.
    parent: :not_given, # A GraphQL query node to be passed as the `:parent` extra.
    lookahead: :not_given, # A GraphQL lookahead object to be passed as the `:lookahead` extra.
    arg_style: :internal_prepared, # Args are in internal format, but should use more rigorous processing,
    field_opts: {}
  )
    # All resolution goes through fields, so we need to create one here that
    # uses our resolver. Thankfully, apart from the field name, resolvers
    # contain all the configuration needed to define one.
    field = ::Types::BaseField.new(
      resolver_class: resolver_class,
      owner: resolver_parent,
      name: 'field_value',
      calls_gitaly: field_opts[:calls_gitaly]
    )

    # All mutations accept a single `:input` argument. Wrap arguments here.
    args = { input: args } if resolver_class <= ::Mutations::BaseMutation && !args.key?(:input)

    resolve_field(
      field,
      obj,
      args: args,
      ctx: ctx,
      schema: schema,
      object_type: resolver_parent,
      extras: { parent: parent, lookahead: lookahead },
      arg_style: arg_style
    )
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
    field,                        # An instance of `BaseField`, or the name of a field on the current described_class
    object,                       # The current object of the `BaseObject` this field 'belongs' to
    args:   {},                   # Field arguments (keys will be fieldnamerized)
    ctx:    {},                   # Context values (important ones are :current_user)
    extras: {},                   # Stub values for field extras (parent and lookahead)
    current_user: :not_given,     # The current user (specified explicitly, overrides ctx[:current_user])
    schema: GitlabSchema,         # A specific schema instance
    object_type: described_class, # The `BaseObject` type this field belongs to
    arg_style: :internal_prepared, # Args are in internal format, but should use more rigorous processing
    query: nil                     # Query to evaluate the field
  )
    field = to_base_field(field, object_type).ensure_loaded
    ctx[:current_user] = current_user unless current_user == :not_given
    query ||= GraphQL::Query.new(schema, context: ctx.to_h)
    extras[:lookahead] = negative_lookahead if extras[:lookahead] == :not_given && field.extras.include?(:lookahead)
    query_ctx = query.context

    mock_extras(query_ctx, **extras)

    parent = object_type.authorized_new(object, query_ctx)
    raise UnauthorizedObject unless parent

    # we enable the request store so we can track gitaly calls.
    ::Gitlab::SafeRequestStore.ensure_request_store do
      prepared_args = case arg_style
                      when :internal_prepared
                        args_internal_prepared(field, args: args, query_ctx: query_ctx, parent: parent, extras: extras, query: query)
                      else
                        args_internal(field, args: args, query_ctx: query_ctx, parent: parent, extras: extras, query: query)
                      end

      if prepared_args.class <= GraphQL::ExecutionError
        prepared_args
      else
        field.resolve(parent, prepared_args, query_ctx)
      end
    end
  end

  # create a valid query context object
  def query_context(user: current_user, request: {})
    query = GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {})
    GraphQL::Query::Context.new(query: query, values: { current_user: user, request: request })
  end

  # rubocop:enable Metrics/ParameterLists

  # Pros:
  #   - Original way we handled arguments
  #
  # Cons:
  #   - the `prepare` method of a type is not called.  Whether as a proc or as a method
  #     on the type, it's not called. For example `:cluster_id` in ee/app/graphql/resolvers/vulnerabilities_resolver.rb,
  #     or `prepare` in app/graphql/types/range_input_type.rb, used by Types::TimeframeInputType
  def args_internal(field, args:, query_ctx:, parent:, extras:, query:)
    arguments = GraphqlHelpers.deep_transform_args(args, field)
    arguments.merge!(extras.reject { |k, v| v == :not_given })
  end

  # Pros:
  #   - Allows the use of ruby types, without having to pass in strings
  #   - All args are converted into strings just like if it was called from a client
  #   - Much stronger argument verification
  #
  # Cons:
  #   - Some values, such as enums, would need to be changed in the specs to use the
  #     external values, because there is no easy way to handle them.
  #
  # take internal style args, and force them into client style args
  def args_internal_prepared(field, args:, query_ctx:, parent:, extras:, query:)
    arguments = GraphqlHelpers.as_graphql_argument_literals(args)
    arguments.merge!(extras.reject { |k, v| v == :not_given })

    # Use public API to properly prepare the args for use by the resolver.
    # It uses `coerce_arguments` under the covers
    prepared_args = nil
    query.arguments_cache.dataload_for(GraphqlHelpers.deep_fieldnamerize(arguments), field, parent) do |kwarg_arguments|
      prepared_args = kwarg_arguments
    end

    prepared_args.respond_to?(:keyword_arguments) ? prepared_args.keyword_arguments : prepared_args
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
      q = double('Query', schema: schema, subscription_update?: subscription_update, warden: GraphQL::Schema::Warden::PassThruWarden)
      allow(q).to receive(:after_lazy) { |value, &block| schema.after_lazy(value, &block) }

      ctx = GraphQL::Query::Context.new(query: q, values: ctx)
    end

    allow(ctx.query).to receive(:subscription_update?).and_return(subscription_update)
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
    ::Gitlab::SafeRequestStore.ensure_request_store do
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

  def graphql_mutation(name, input, fields = nil, excluded = [], operation_name = nil, &block)
    raise ArgumentError, 'Please pass either `fields` parameter or a block to `#graphql_mutation`, but not both.' if fields.present? && block

    name = name.graphql_name if name.respond_to?(:graphql_name)
    mutation_name = GraphqlHelpers.fieldnamerize(name)
    input_variable_name = "$#{input_variable_name_for_mutation(name)}"
    mutation_field = GitlabSchema.mutation.fields[mutation_name]
    operation_name = " #{operation_name}" if operation_name.present?

    fields = yield if block
    fields ||= all_graphql_fields_for(mutation_field.type.to_type_signature, excluded: excluded)

    query = <<~MUTATION
      mutation#{operation_name}(#{input_variable_name}: #{mutation_field.arguments['input'].type.to_type_signature}) {
        #{mutation_name}(input: #{input_variable_name}) {
          #{fields}
        }
      }
    MUTATION
    variables = variables_for_mutation(name, input)

    MutationDefinition.new(query, variables)
  end

  def variables_for_mutation(name, input)
    graphql_input = prepare_variables(input)

    { input_variable_name_for_mutation(name) => graphql_input }
  end

  def serialize_variables(variables)
    return unless variables
    return variables if variables.is_a?(String)

    # Combine variables into a single hash.
    hash = ::Gitlab::Utils::MergeHash.merge(Array.wrap(variables).map(&:to_h))

    prepare_variables(hash).to_json
  end

  # Recursively convert any ruby object we can pass as a variable value
  # to an object we can serialize with JSON, using fieldname-style keys
  #
  # prepare_variables({ 'my_key' => 1 })
  #   => { 'myKey' => 1 }
  # prepare_variables({ enums: [:FOO, :BAR], user_id: global_id_of(user) })
  #   => { 'enums' => ['FOO', 'BAR'], 'userId' => "gid://User/123" }
  # prepare_variables({ nested: { hash_values: { are_supported: true } } })
  #   => { 'nested' => { 'hashValues' => { 'areSupported' => true } } }
  def prepare_variables(input)
    return input.map { prepare_variables(_1) } if input.is_a?(Array)
    return input.to_s if input.is_a?(GlobalID) || input.is_a?(Symbol)
    return input unless input.is_a?(Hash)

    input.to_h do |name, value|
      [GraphqlHelpers.fieldnamerize(name), prepare_variables(value)]
    end
  end

  def input_variable_name_for_mutation(mutation_name)
    mutation_name = GraphqlHelpers.fieldnamerize(mutation_name)
    mutation_field = GitlabSchema.mutation.fields[mutation_name]
    input_type = mutation_field.arguments['input'].type.unwrap.to_type_signature

    GraphqlHelpers.fieldnamerize(input_type)
  end

  def field_with_params(name, attributes = {})
    namerized = GraphqlHelpers.fieldnamerize(name.to_s)
    return namerized.to_s if attributes.blank?

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

  def query_double(schema: empty_schema)
    double('query', schema: schema, warden: GraphQL::Schema::Warden::PassThruWarden)
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

  def all_graphql_fields_for(class_name, max_depth: 3, excluded: [])
    # pulling _all_ fields can generate a _huge_ query (like complexity 180,000),
    # and significantly increase spec runtime. so limit the depth by default
    return if max_depth <= 0

    allow_unlimited_graphql_complexity
    allow_unlimited_graphql_depth if max_depth > 1
    allow_unlimited_validation_timeout
    allow_high_graphql_recursion
    allow_high_graphql_transaction_threshold
    allow_high_graphql_query_size

    type = class_name.respond_to?(:kind) ? class_name : GitlabSchema.types[class_name.to_s]
    raise "#{class_name} is not a known type in the GitlabSchema" unless type

    # We can't guess arguments, so skip fields that require them
    skip = ->(name, field) { excluded.include?(name) || required_arguments?(field) }

    ::Graphql::FieldSelection.select_fields(type, skip, max_depth)
  end

  def with_signature(variables, query)
    %[query(#{variables.map(&:sig).join(', ')}) #{wrap_query(query)}]
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
    post_graphql(
      mutation.query,
      current_user: current_user,
      variables: mutation.variables,
      token: token
    )
  end

  def post_graphql_mutation_with_uploads(mutation, current_user: nil)
    file_paths = file_paths_in_mutation(mutation)
    params = mutation_to_apollo_uploads_param(mutation, files: file_paths)

    workhorse_post_with_file(
      api('/', current_user, version: 'graphql'),
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
      if memo.is_a?(Array) && key.is_a?(Integer)
        memo[key]
      elsif memo.is_a?(Array)
        memo.compact.flat_map do |e|
          x = e[key]
          x.nil? ? [x] : Array.wrap(x)
        end
      else
        memo&.dig(key)
      end
    end
  end

  def graphql_errors(body = fresh_response_data)
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
    # TODO: using eq([]) instead of be_empty makes it print out the full error message including the
    #       raisedAt key which contains the full stacktrace. This is necessary to know where the
    #       unexpected error occurred during tests.
    #       This or an equivalent fix should be added in a separate MR on master.
    expect(flattened_errors).to eq([])
  end

  # Helps migrate to the new GraphQL interpreter,
  # https://gitlab.com/gitlab-org/gitlab/-/issues/210556
  def expect_graphql_error_to_be_created(error_class, match_message = '')
    resolved = yield

    expect(resolved).to be_instance_of(error_class)
    expect(resolved.message).to match(match_message)
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

  def allow_unlimited_validation_timeout
    allow_any_instance_of(GitlabSchema).to receive(:validate_timeout).and_return nil
    allow(GitlabSchema).to receive(:validate_timeout).with(any_args).and_return nil
  end

  def allow_high_graphql_recursion
    allow_any_instance_of(Gitlab::Graphql::QueryAnalyzers::AST::RecursionAnalyzer).to receive(:recursion_threshold).and_return 1000
  end

  def allow_high_graphql_transaction_threshold
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(1000)
  end

  def allow_high_graphql_query_size
    stub_const('GraphqlController::MAX_QUERY_SIZE', 10_000_000)
  end

  def node_array(data, extract_attribute = nil)
    data.map do |item|
      extract_attribute ? item['node'][extract_attribute] : item['node']
    end
  end

  def global_id_of(model = nil, id: nil, model_name: nil)
    if id || model_name
      ::Gitlab::GlobalId.as_global_id(id || model.id, model_name: model_name || model.class.name)
    else
      model.to_global_id
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

      field :name, GraphQL::Types::String, null: true

      yield(self) if block_given?
    end
  end

  def query_factory
    Class.new(Types::BaseObject) do
      graphql_name 'TestQuery'

      yield(self) if block_given?
    end
  end

  # assumes query_string and user to be let-bound in the current context
  def execute_query(query_type = Types::QueryType, schema: empty_schema, graphql: query_string, raise_on_error: false, variables: {})
    schema.query(query_type)

    r = schema.execute(
      graphql,
      context: { current_user: user },
      variables: variables
    )

    if raise_on_error && r.to_h['errors'].present?
      raise NoData, r.to_h['errors']
    end

    r
  end

  def empty_schema
    Class.new(GraphQL::Schema) do
      use Gitlab::Graphql::Pagination::Connections
      use BatchLoader::GraphQL

      lazy_resolve ::Gitlab::Graphql::Lazy, :force
    end
  end

  # Wrapper around a_hash_including that supports unpacking with **
  class UnpackableMatcher < SimpleDelegator
    include RSpec::Matchers

    attr_reader :to_hash

    def initialize(hash)
      @to_hash = hash
      super(a_hash_including(hash))
    end

    def to_json(_opts = {})
      to_hash.to_json
    end

    def as_json(opts = {})
      to_hash.as_json(opts)
    end
  end

  # Construct a matcher for GraphQL entity response objects, of the form
  # `{ "id" => "some-gid" }`.
  #
  # Usage:
  #
  # ```ruby
  # expect(graphql_data_at(:path, :to, :entity)).to match a_graphql_entity_for(user)
  # ```
  #
  # This can be called as:
  #
  # ```ruby
  # a_graphql_entity_for(project, :full_path) # also checks that `entity['fullPath'] == project.full_path
  # a_graphql_entity_for(project, full_path: 'some/path') # same as above, with explicit values
  # a_graphql_entity_for(user, :username, foo: 'bar') # combinations of the above
  # a_graphql_entity_for(foo: 'bar') # if properties are defined, the model is not necessary
  # ```
  #
  # Note that the model instance must not be nil, unless some properties are
  # explicitly passed in. The following are rejected with `ArgumentError`:
  #
  # ```
  # a_graphql_entity_for(nil, :username)
  # a_graphql_entity_for(:username)
  # a_graphql_entity_for
  # ```
  #
  def a_graphql_entity_for(model = nil, *fields, **attrs)
    raise ArgumentError, 'model is nil' if model.nil? && fields.any?

    attrs.transform_keys! { GraphqlHelpers.fieldnamerize(_1) }
    attrs['id'] = global_id_of(model).to_s if model
    fields.each do |name|
      attrs[GraphqlHelpers.fieldnamerize(name)] = model.public_send(name)
    end

    raise ArgumentError, 'no attributes' if attrs.empty?

    UnpackableMatcher.new(attrs)
  end

  # A lookahead that selects everything
  def positive_lookahead
    double(selected?: true, selects?: true).tap do |selection|
      allow(selection).to receive(:selection).and_return(selection)
      allow(selection).to receive(:selections).and_return(selection)
      allow(selection).to receive(:map).and_return(double(include?: true))
    end
  end

  # A lookahead that selects nothing
  def negative_lookahead
    double(selected?: false, selects?: false, selections: []).tap do |selection|
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
