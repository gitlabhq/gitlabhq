# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/query')

RSpec.describe Tooling::Graphql::Docs::Schema::Query, feature_category: :api do
  let_it_be(:mock_query_type) do
    Class.new(Types::BaseObject) do
      graphql_name 'Query'

      field :find_thing, GraphQL::Types::String, null: true, description: 'Find a thing.' do
        argument :name, GraphQL::Types::String, required: true, description: 'Name of the thing.'
      end
    end
  end

  subject(:query) { described_class.new(mock_query_type.fields['findThing']) }

  it 'is a field' do
    expect(query).to be_a(Tooling::Graphql::Docs::Schema::Field)
  end

  it 'has correct properties' do
    expect(query).to have_attributes(
      name: 'findThing',
      description: 'Find a thing.',
      type: be_a(Tooling::Graphql::Docs::Schema::Scalar),
      type_signature: 'String',
      arguments: contain_exactly(have_attributes(name: 'name'))
    )
  end
end
