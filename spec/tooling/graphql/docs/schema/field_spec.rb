# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/field')

RSpec.describe Tooling::Graphql::Docs::Schema::Field, feature_category: :api do
  let_it_be(:mock_graphql_object) do
    Class.new(Types::BaseObject) do
      field :object_field, GraphQL::Types::Boolean, description: 'A GraphQL field' do
        argument :argument, GraphQL::Types::String
      end

      field :referenced_field, GraphQL::Types::Boolean, description: 'A field',
        see: { 'GitLab docs' => 'https://docs.gitlab.com/example' }

      field :experimental, GraphQL::Types::Boolean, experiment: { milestone: '16.0' }
      field :deprecated, GraphQL::Types::Boolean, deprecated: { milestone: '16.0', reason: 'Deprecated' }
    end
  end

  let(:object_fields) { mock_graphql_object.fields }

  subject(:field) { described_class.new(object_fields['objectField']) }

  it 'has correct properties' do
    expect(field).to have_attributes(
      item: kind_of(Types::BaseField),
      name: 'objectField',
      type: have_attributes(name: 'Boolean'),
      type_signature: 'Boolean',
      description: 'A GraphQL field',
      arguments: contain_exactly(kind_of(Tooling::Graphql::Docs::Schema::Argument))
    )
  end

  describe '#doc_reference' do
    subject(:field) { described_class.new(object_fields['referencedField']) }

    it 'returns the see reference hash' do
      expect(field.doc_reference).to eq({ 'GitLab docs' => 'https://docs.gitlab.com/example' })
    end
  end

  describe '#connection? and #arguments_without_pagination' do
    let_it_be(:mock_graphql_object) do
      node_type = Class.new(Types::BaseObject) do
        graphql_name 'ConnectionNode'

        field :id, GraphQL::Types::ID, null: false
      end

      Class.new(Types::BaseObject) do
        field :items, node_type.connection_type, null: true, description: 'A connection field' do
          argument :search, GraphQL::Types::String, required: false
        end

        field :name, GraphQL::Types::String, null: true, description: 'A plain field'
      end
    end

    context 'when the field is a connection' do
      subject(:field) { described_class.new(object_fields['items']) }

      it 'is a connection' do
        expect(field).to be_connection
      end

      it 'excludes the standard pagination arguments', :aggregate_failures do
        expect(field.arguments.map(&:name)).to include('after', 'before', 'first', 'last', 'search')
        expect(field.arguments_without_pagination.map(&:name)).to contain_exactly('search')
      end
    end

    context 'when the field is not a connection' do
      subject(:field) { described_class.new(object_fields['name']) }

      it 'is not a connection' do
        expect(field).not_to be_connection
      end

      it 'returns all arguments' do
        expect(field.arguments_without_pagination).to eq(field.arguments)
      end
    end
  end

  it_behaves_like Tooling::Graphql::Docs::Schema::Deprecable do
    let(:experimental_item) { described_class.new(object_fields['experimental']) }
    let(:deprecated_item) { described_class.new(object_fields['deprecated']) }
  end
end
