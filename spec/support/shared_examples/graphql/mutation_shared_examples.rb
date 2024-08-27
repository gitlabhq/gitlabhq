# frozen_string_literal: true

# Shared example for expecting top-level errors.
# See https://graphql-ruby.org/mutations/mutation_errors#raising-errors
#
#   { errors: [] }
#
# There must be a method or let called `mutation` defined that executes
# the mutation.
RSpec.shared_examples 'a mutation that returns top-level errors' do |errors: []|
  let(:match_errors) { match_array(errors) }

  it do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(graphql_errors).to be_present

    error_messages = graphql_errors.pluck('message')

    expect(error_messages).to match_errors
  end
end

# There must be a method or let called `mutation` defined that executes
# the mutation.
RSpec.shared_examples 'a mutation that returns a top-level access error' do
  include_examples 'a mutation that returns top-level errors',
    errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
end

RSpec.shared_examples 'an invalid argument to the mutation' do |argument_name:|
  it_behaves_like 'a mutation that returns top-level errors' do
    let(:match_errors) do
      contain_exactly(include("invalid value for #{GraphqlHelpers.fieldnamerize(argument_name)}"))
    end
  end
end

# Shared example for expecting schema-level errors.
# See https://graphql-ruby.org/mutations/mutation_errors#errors-as-data
#
#   { data: { mutationName: { errors: [] } } }
#
# There must be:
# - a method or let called `mutation` defined that executes the mutation
# - a `mutation_response` method defined that returns the data of the mutation response.
RSpec.shared_examples 'a mutation that returns errors in the response' do |errors:|
  it do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response['errors']).to match_array(errors)
  end
end

RSpec.shared_examples 'a query that returns a top-level access error' do
  it do
    expect(graphql_errors).to be_present

    error_messages = graphql_errors.pluck('message')

    errors = [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    expect(error_messages).to match_array(errors)
  end
end
