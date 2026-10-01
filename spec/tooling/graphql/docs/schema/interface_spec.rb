# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/interface')

RSpec.describe Tooling::Graphql::Docs::Schema::Interface, feature_category: :api do
  let_it_be(:mock_graphql_interface) do
    Module.new do
      include Types::BaseInterface
      graphql_name 'MockGraphQLInterface'
      description 'Interface description'

      field :interface_field, GraphQL::Types::Boolean, null: true
    end
  end

  subject(:interface) { described_class.new(mock_graphql_interface) }

  it 'has correct properties' do
    expect(interface).to have_attributes(
      name: 'MockGraphQLInterface',
      description: 'Interface description',
      fields: contain_exactly(kind_of(Tooling::Graphql::Docs::Schema::Field))
    )
  end

  context 'without fields' do
    subject(:interface) { described_class.new(mock_graphql_interface, with_fields: false) }

    it 'has no fields' do
      expect(interface.fields).to be_nil
    end
  end

  describe '#implementations' do
    context 'when none are given' do
      it 'is empty' do
        expect(interface.implementations).to be_empty
      end
    end

    context 'when given implementations out of order' do
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

      subject(:interface) do
        described_class.new(mock_graphql_interface, implementations: [zebra_object, alpha_object])
      end

      it 'wraps the implementations and sorts them alphabetically', :aggregate_failures do
        expect(interface.implementations).to all(be_a(Tooling::Graphql::Docs::Schema::Object))
        expect(interface.implementations.map(&:name)).to eq(%w[AlphaObject ZebraObject])
      end

      it 'wraps the implementations without loading their fields' do
        expect(interface.implementations.map(&:fields)).to all(be_nil)
      end
    end
  end
end
