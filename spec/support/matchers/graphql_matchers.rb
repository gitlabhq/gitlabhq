# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :be_nullable, :be_non_null

RSpec::Matchers.define :require_graphql_authorizations do |*expected|
  match do |klass|
    permissions = if klass.respond_to?(:required_permissions)
                    klass.required_permissions
                  else
                    [klass.to_graphql.metadata[:authorize]]
                  end

    expect(permissions).to eq(expected)
  end
end

RSpec::Matchers.define :have_graphql_fields do |*expected|
  def expected_field_names
    Array.wrap(expected).map { |name| GraphqlHelpers.fieldnamerize(name) }
  end

  @allow_extra = false

  chain :only do
    @allow_extra = false
  end

  chain :at_least do
    @allow_extra = true
  end

  match do |kls|
    keys   = kls.fields.keys.to_set
    fields = expected_field_names.to_set

    next true if fields == keys
    next true if @allow_extra && fields.proper_subset?(keys)

    false
  end

  failure_message do |kls|
    missing = expected_field_names - kls.fields.keys
    extra = kls.fields.keys - expected_field_names

    message = []

    message << "is missing fields: <#{missing.inspect}>" if missing.any?
    message << "contained unexpected fields: <#{extra.inspect}>" if extra.any? && !@allow_extra

    message.join("\n")
  end
end

RSpec::Matchers.define :include_graphql_fields do |*expected|
  expected_field_names = expected.map { |name| GraphqlHelpers.fieldnamerize(name) }

  match do |kls|
    expect(kls.fields.keys).to include(*expected_field_names)
  end

  failure_message do |kls|
    missing = expected_field_names - kls.fields.keys
    "is missing fields: <#{missing.inspect}>" if missing.any?
  end
end

RSpec::Matchers.define :have_graphql_field do |field_name, args = {}|
  match do |kls|
    field = kls.fields[GraphqlHelpers.fieldnamerize(field_name)]

    expect(field).to be_present

    args.each do |argument, value|
      expect(field.send(argument)).to eq(value)
    end
  end
end

RSpec::Matchers.define :have_graphql_mutation do |mutation_class|
  match do |mutation_type|
    field = mutation_type.fields[GraphqlHelpers.fieldnamerize(mutation_class.graphql_name)]

    expect(field).to be_present
    expect(field.resolver).to eq(mutation_class)
  end
end

# note: connection arguments do not have to be named, they will be inferred.
RSpec::Matchers.define :have_graphql_arguments do |*expected|
  include GraphqlHelpers

  def expected_names(field)
    @names ||= Array.wrap(expected).map { |name| GraphqlHelpers.fieldnamerize(name) }

    if field.type.try(:ancestors)&.include?(GraphQL::Types::Relay::BaseConnection)
      @names | %w[after before first last]
    else
      @names
    end
  end

  match do |field|
    names = expected_names(field)

    expect(field.arguments.keys).to contain_exactly(*names)
  end

  failure_message do |field|
    names = expected_names(field).inspect
    args = field.arguments.keys.inspect

    "expected #{field.name} to have the following arguments: #{names}, but it has #{args}."
  end
end

module GraphQLTypeHelpers
  def message(object, expected, **opts)
    non_null = expected.non_null? || (opts.key?(:null) && !opts[:null])

    actual = object.type
    actual_type = actual.unwrap.graphql_name
    actual_type += '!' if actual.non_null?

    expected_type = expected.unwrap.graphql_name
    expected_type += '!' if non_null

    "expected #{describe_object(object)} to have GraphQL type #{expected_type}, but got #{actual_type}"
  end

  def describe_object(object)
    case object
    when Types::BaseField
      "#{describe_object(object.owner_type)}.#{object.graphql_name}"
    when Types::BaseArgument
      "#{describe_object(object.owner)}.#{object.graphql_name}"
    when Class
      object.try(:graphql_name) || object.name
    else
      object.to_s
    end
  end

  def nullified(type, can_be_nil)
    return type if can_be_nil.nil? # unknown!
    return type if can_be_nil

    type.to_non_null_type
  end
end

RSpec::Matchers.define :have_graphql_type do |expected, opts = {}|
  include GraphQLTypeHelpers

  match do |object|
    expect(object.type).to eq(nullified(expected, opts[:null]))
  end

  failure_message do |object|
    message(object, expected, **opts)
  end
end

RSpec::Matchers.define :have_nullable_graphql_type do |expected|
  include GraphQLTypeHelpers

  match do |object|
    expect(object).to have_graphql_type(expected.unwrap, { null: true })
  end

  description do
    "have nullable GraphQL type #{expected.graphql_name}"
  end

  failure_message do |object|
    message(object, expected, null: true)
  end
end

RSpec::Matchers.define :have_non_null_graphql_type do |expected|
  include GraphQLTypeHelpers

  match do |object|
    expect(object).to have_graphql_type(expected, { null: false })
  end

  description do
    "have non-null GraphQL type #{expected.graphql_name}"
  end

  failure_message do |object|
    message(object, expected, null: false)
  end
end

RSpec::Matchers.define :have_graphql_resolver do |expected|
  match do |field|
    case expected
    when Method
      expect(field.to_graphql.metadata[:type_class].resolve_proc).to eq(expected)
    else
      expect(field.to_graphql.metadata[:type_class].resolver).to eq(expected)
    end
  end
end

RSpec::Matchers.define :have_graphql_extension do |expected|
  match do |field|
    expect(field.to_graphql.metadata[:type_class].extensions).to include(expected)
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
