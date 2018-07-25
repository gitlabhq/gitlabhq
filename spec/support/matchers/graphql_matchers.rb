RSpec::Matchers.define :require_graphql_authorizations do |*expected|
  match do |field|
    field_definition = field.metadata[:type_class]
    expect(field_definition).to respond_to(:required_permissions)
    expect(field_definition.required_permissions).to contain_exactly(*expected)
  end
end

RSpec::Matchers.define :have_graphql_fields do |*expected|
  def expected_field_names
    expected.map { |name| GraphqlHelpers.fieldnamerize(name) }
  end

  match do |kls|
    expect(kls.fields.keys).to contain_exactly(*expected_field_names)
  end

  failure_message do |kls|
    missing = expected_field_names - kls.fields.keys
    extra = kls.fields.keys - expected_field_names

    message = []

    message << "is missing fields: <#{missing.inspect}>" if missing.any?
    message << "contained unexpected fields: <#{extra.inspect}>" if extra.any?

    message.join("\n")
  end
end

RSpec::Matchers.define :have_graphql_field do |field_name|
  match do |kls|
    expect(kls.fields.keys).to include(GraphqlHelpers.fieldnamerize(field_name))
  end
end

RSpec::Matchers.define :have_graphql_arguments do |*expected|
  include GraphqlHelpers

  match do |field|
    argument_names = expected.map { |name| GraphqlHelpers.fieldnamerize(name) }
    expect(field.arguments.keys).to contain_exactly(*argument_names)
  end
end

RSpec::Matchers.define :have_graphql_type do |expected|
  match do |field|
    expect(field.type).to eq(expected.to_graphql)
  end
end

RSpec::Matchers.define :have_graphql_resolver do |expected|
  match do |field|
    case expected
    when Method
      expect(field.metadata[:type_class].resolve_proc).to eq(expected)
    else
      expect(field.metadata[:type_class].resolver).to eq(expected)
    end
  end
end

RSpec::Matchers.define :expose_permissions_using do |expected|
  match do |type|
    permission_field = type.fields['userPermissions']

    expect(permission_field).not_to be_nil
    expect(permission_field.type).to be_non_null
    expect(permission_field.type.of_type.graphql_name).to eq(expected.graphql_name)
  end
end
