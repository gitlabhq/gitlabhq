# frozen_string_literal: true

# Shared example for expecting top-level errors.
# See https://graphql-ruby.org/mutations/mutation_errors#raising-errors
#
#   { errors: [] }
#
# There must be a method or let called `mutation` defined that executes
# the mutation.
RSpec.shared_examples 'a mutation that returns top-level errors' do |errors:|
  it do
    post_graphql_mutation(mutation, current_user: current_user)

    error_messages = graphql_errors.map { |e| e['message'] }

    expect(error_messages).to eq(errors)
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

    expect(mutation_response['errors']).to eq(errors)
  end
end
