RSpec::Matchers.define :require_graphql_authorizations do |*expected|
  match do |field|
    field_definition = field.metadata[:type_class]
    expect(field_definition).to respond_to(:required_permissions)
    expect(field_definition.required_permissions).to contain_exactly(*expected)
  end
end

RSpec::Matchers.define :have_graphql_fields do |*expected|
  match do |kls|
    field_names = expected.map { |name| GraphqlHelpers.fieldnamerize(name) }
    expect(kls.fields.keys).to contain_exactly(*field_names)
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
