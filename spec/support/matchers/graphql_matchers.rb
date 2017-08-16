RSpec::Matchers.define :require_graphql_authorizations do |*expected|
  match do |field|
    authorizations = field.metadata[:authorize]

    expect(authorizations).to contain_exactly(*expected)
  end
end

RSpec::Matchers.define :have_graphql_fields do |*expected|
  match do |kls|
    expect(kls.fields.keys).to contain_exactly(*expected.map(&:to_s))
  end
end

RSpec::Matchers.define :have_graphql_arguments do |*expected|
  match do |field|
    expect(field.arguments.keys).to contain_exactly(*expected.map(&:to_s))
  end
end

RSpec::Matchers.define :have_graphql_type do |expected|
  match do |field|
    expect(field.type).to eq(expected)
  end
end

RSpec::Matchers.define :have_graphql_resolver do |expected|
  match do |field|
    expect(field.resolve_proc).to eq(expected)
  end
end
