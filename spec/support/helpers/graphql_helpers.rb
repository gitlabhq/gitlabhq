module GraphqlHelpers
  # Run a loader's named resolver
  def resolve(kls, name, obj: nil, args: {}, ctx: {})
    kls[name].call(obj, args, ctx)
  end

  # Runs a block inside a BatchLoader::Executor wrapper
  def batch(max_queries: nil, &blk)
    wrapper = proc do
      begin
        BatchLoader::Executor.ensure_current
        yield
      ensure
        BatchLoader::Executor.clear_current
      end
    end

    if max_queries
      result = nil
      expect { result = wrapper.call }.not_to exceed_query_limit(max_queries)
      result
    else
      wrapper.call
    end
  end

  def all_graphql_fields_for(klass)
    type = GitlabSchema.types[klass.name]
    return "" unless type

    type.fields.map do |name, field|
      if scalar?(field)
        name
      else
        "#{name} { #{all_graphql_fields_for(field_type(field))} }"
      end
    end.join("\n")
  end

  def post_graphql(query)
    post '/api/graphql', query: query
  end

  def scalar?(field)
    field_type(field).kind.scalar?
  end

  def field_type(field)
    if field.type.respond_to?(:of_type)
      field.type.of_type
    else
      field.type
    end
  end
end
