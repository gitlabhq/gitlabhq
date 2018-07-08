module GraphqlHelpers
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

  def graphql_query_for(name, attributes = {}, fields = nil)
    <<~QUERY
    {
      #{query_graphql_field(name, attributes, fields)}
    }
    QUERY
  end

  def query_graphql_field(name, attributes = {}, fields = nil)
    fields ||= all_graphql_fields_for(name.classify)
    attributes = attributes_to_graphql(attributes)
    <<~QUERY
      #{name}(#{attributes}) {
        #{fields}
      }
    QUERY
  end

  def all_graphql_fields_for(class_name)
    type = GitlabSchema.types[class_name.to_s]
    return "" unless type

    type.fields.map do |name, field|
      # We can't guess arguments, so skip fields that require them
      next if required_arguments?(field)

      if nested_fields?(field)
        "#{name} { #{all_graphql_fields_for(field_type(field))} }"
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

  def post_graphql(query, current_user: nil)
    post api('/', current_user, version: 'graphql'), query: query
  end

  def graphql_data
    json_response['data']
  end

  def graphql_errors
    json_response['data']
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

  def field_type(field)
    if field.type.respond_to?(:of_type)
      field.type.of_type
    else
      field.type
    end
  end
end
