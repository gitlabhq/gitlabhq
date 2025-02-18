# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :be_nullable, :be_non_null

RSpec::Matchers.define :require_graphql_authorizations do |*expected|
  def permissions_for(klass)
    if klass.respond_to?(:required_permissions)
      klass.required_permissions
    else
      Array.wrap(klass.authorize)
    end
  end

  match do |klass|
    actual = permissions_for(klass)

    expect(actual).to match_array(expected.compact)
  end

  failure_message do |klass|
    actual = permissions_for(klass)
    missing = actual - expected
    extra = expected - actual

    message = []
    message << "is missing permissions: #{missing.inspect}" if missing.any?
    message << "contained unexpected permissions: #{extra.inspect}" if extra.any?

    message.join("\n")
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

  match do |field|
    names = expected_names(field)

    expect(field.arguments.keys).to contain_exactly(*names)
  end

  failure_message do |field|
    expected_values = expected_names(field).sort
    actual_values = field.arguments.keys.sort

    extra_values = actual_values - expected_values
    missing_values = expected_values - actual_values

    message = <<~MESSAGE
    expected #{field.name} to have the following arguments:
    #{expected_values.inspect}
    but it has
    #{actual_values.inspect}
    MESSAGE

    if extra_values.present?
      message += <<~MESSAGE
      \n Extra values:
      #{extra_values.inspect}
      MESSAGE
    end

    if missing_values.present?
      message += <<~MESSAGE
      \n Missing values:
      #{missing_values.inspect}
      MESSAGE
    end

    message
  end
end

RSpec::Matchers.define :include_graphql_arguments do |*expected|
  include GraphqlHelpers

  match do |field|
    names = expected_names(field)

    expect(field.arguments.keys).to include(*names)
  end

  failure_message do |field|
    names = expected_names(field).inspect
    args = field.arguments.keys.inspect

    missing = names - args
    "is missing fields: <#{missing.inspect}>" if missing.any?
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
    if object.type.list?
      expect(object.type.unwrap).to eq(nullified(expected, opts[:null]))
    else
      expect(object.type).to eq(nullified(expected, opts[:null]))
    end
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
    expect(field.resolver).to eq(expected)
  end
end

RSpec::Matchers.define :have_graphql_extension do |expected|
  match do |field|
    expect(field.extensions).to include(expected)
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

RSpec::Matchers.define :have_graphql_name do |expected|
  def graphql_name(object)
    object.graphql_name if object.respond_to?(:graphql_name)
  end

  match do |object|
    name = graphql_name(object)

    begin
      if expected.present?
        expect(name).to eq(expected)
      else
        expect(expected).to be_present
      end
    rescue RSpec::Expectations::ExpectationNotMetError => error
      @error = error
      raise
    end
  end

  failure_message do |object|
    if expected.present?
      @error
    else
      'Expected graphql_name value cannot be blank'
    end
  end
end

RSpec::Matchers.define :have_graphql_description do |expected|
  def graphql_description(object)
    object.description if object.respond_to?(:description)
  end

  match do |object|
    description = graphql_description(object)

    begin
      if expected.present?
        expect(description).to eq(expected)
      else
        expect(description).to be_present
      end
    rescue RSpec::Expectations::ExpectationNotMetError => error
      @error = error
      raise
    end
  end

  failure_message do |object|
    if expected.present?
      @error
    else
      "have_graphql_description expected value cannot be blank"
    end
  end
end

def expected_names(field)
  @names ||= Array.wrap(expected).map { |name| GraphqlHelpers.fieldnamerize(name) }

  if field.try(:type).try(:ancestors)&.include?(GraphQL::Types::Relay::BaseConnection)
    @names | %w[after before first last]
  else
    @names
  end
end
