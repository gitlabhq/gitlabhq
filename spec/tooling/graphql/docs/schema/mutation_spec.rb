# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/mutation')

RSpec.describe Tooling::Graphql::Docs::Schema::Mutation, feature_category: :api do
  let_it_be(:mutation_field) do
    mutation_class = Class.new(::Mutations::BaseMutation) do
      graphql_name 'MockMutation'
      description 'A mock mutation.'

      argument :name, GraphQL::Types::String, required: true, description: 'Name of the thing.'

      field :thing, GraphQL::Types::String, null: true, description: 'Created thing.'
    end

    Class.new(::Types::BaseObject) do
      graphql_name 'Mutation'

      field :mock_mutation, mutation: mutation_class
    end.fields['mockMutation']
  end

  subject(:mutation) { described_class.new(mutation_field) }

  it 'is a field' do
    expect(mutation).to be_a(Tooling::Graphql::Docs::Schema::Field)
  end

  it 'has correct properties' do
    expect(mutation).to have_attributes(
      name: 'mockMutation',
      description: 'A mock mutation.',
      input_object_name: 'MockMutationInput'
    )
  end

  it 'uses the input object arguments as its arguments, without clientMutationId', :aggregate_failures do
    expect(mutation.arguments).to all(be_a(Tooling::Graphql::Docs::Schema::Argument))
    expect(mutation.arguments.map(&:name)).to contain_exactly('name')
  end

  it 'uses the payload fields as its return fields, without clientMutationId', :aggregate_failures do
    expect(mutation.return_fields).to all(be_a(Tooling::Graphql::Docs::Schema::Field))
    expect(mutation.return_fields.map(&:name)).to contain_exactly('errors', 'thing')
  end
end
