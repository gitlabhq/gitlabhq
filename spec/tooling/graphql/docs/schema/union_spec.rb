# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/union')

RSpec.describe Tooling::Graphql::Docs::Schema::Union, feature_category: :api do
  let_it_be(:member_object) do
    Class.new(Types::BaseObject) do
      graphql_name 'MemberObject'
      field :id, GraphQL::Types::ID, null: true
    end
  end

  let_it_be(:mock_graphql_union) do
    member = member_object

    Class.new(Types::BaseUnion) do
      graphql_name 'MockGraphQLUnion'
      description 'Union description'
      possible_types member
    end
  end

  subject(:union) { described_class.new(mock_graphql_union) }

  it 'has correct properties' do
    expect(union).to have_attributes(
      name: 'MockGraphQLUnion',
      description: 'Union description'
    )
  end

  describe '#members' do
    context 'when none are given' do
      it 'is empty' do
        expect(union.members).to be_empty
      end
    end

    context 'when given members out of order' do
      let_it_be(:zebra_object) do
        Class.new(Types::BaseObject) do
          graphql_name 'ZebraObject'
          field :id, GraphQL::Types::ID, null: true
        end
      end

      let_it_be(:alpha_object) do
        Class.new(Types::BaseObject) do
          graphql_name 'AlphaObject'
          field :id, GraphQL::Types::ID, null: true
        end
      end

      subject(:union) { described_class.new(mock_graphql_union, members: [zebra_object, alpha_object]) }

      it 'wraps the members as objects and sorts them alphabetically', :aggregate_failures do
        expect(union.members).to all(be_a(Tooling::Graphql::Docs::Schema::Object))
        expect(union.members.map(&:name)).to eq(%w[AlphaObject ZebraObject])
      end

      it 'wraps the members without loading their fields' do
        expect(union.members.map(&:fields)).to all(be_nil)
      end
    end
  end
end
