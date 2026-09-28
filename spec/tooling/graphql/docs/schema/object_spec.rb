# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/object')
require Rails.root.join('tooling/graphql/docs/schema/field')

RSpec.describe Tooling::Graphql::Docs::Schema::Object, feature_category: :api do
  let_it_be(:mock_graphql_object) do
    Class.new(Types::BaseObject) do
      graphql_name 'MockGraphQLObject'
      description 'Object description'
      field :object_field, GraphQL::Types::Boolean
    end
  end

  subject(:object) { described_class.new(mock_graphql_object) }

  it 'has correct properties' do
    expect(object).to have_attributes(
      name: 'MockGraphQLObject',
      description: 'Object description',
      fields: contain_exactly(kind_of(Tooling::Graphql::Docs::Schema::Field))
    )
  end

  describe '#implemented_interfaces' do
    context 'when the object implements no interfaces' do
      it 'is empty' do
        expect(object.implemented_interfaces).to be_empty
      end
    end

    context 'when the object implements interfaces declared out of order' do
      let_it_be(:zebra_interface) do
        Module.new do
          include Types::BaseInterface
          graphql_name 'ZebraInterface'

          field :id, GraphQL::Types::ID, null: true
        end
      end

      let_it_be(:alpha_interface) do
        Module.new do
          include Types::BaseInterface
          graphql_name 'AlphaInterface'

          field :id, GraphQL::Types::ID, null: true
        end
      end

      let_it_be(:mock_graphql_object) do
        zebra = zebra_interface
        alpha = alpha_interface

        Class.new(Types::BaseObject) do
          graphql_name 'MultiInterfaceObject'

          implements zebra
          implements alpha

          field :object_field, GraphQL::Types::Boolean
        end
      end

      it 'returns the interface names sorted alphabetically' do
        expect(object.implemented_interfaces).to eq(%w[AlphaInterface ZebraInterface])
      end
    end
  end

  context 'without fields' do
    subject(:object) { described_class.new(mock_graphql_object, with_fields: false) }

    it 'has no fields' do
      expect(object.fields).to be_nil
    end
  end

  describe 'relay type helpers' do
    let_it_be(:node_type) do
      Class.new(Types::BaseObject) do
        graphql_name 'Node'

        field :id, GraphQL::Types::ID, null: false
      end
    end

    context 'with an ordinary object type' do
      it 'is neither a connection nor an edge', :aggregate_failures do
        expect(object).not_to be_connection
        expect(object).not_to be_edge
      end

      it 'has no node type' do
        expect(object.node_type).to be_nil
      end
    end

    context 'with a connection type' do
      subject(:object) { described_class.new(node_type.connection_type) }

      it 'is a connection', :aggregate_failures do
        expect(object).to be_connection
        expect(object).not_to be_edge
      end

      it 'wraps the node type as an Object', :aggregate_failures do
        expect(object.node_type).to be_a(described_class)
        expect(object.node_type.name).to eq('Node')
      end
    end

    context 'with an edge type' do
      subject(:object) { described_class.new(node_type.edge_type) }

      it 'is an edge', :aggregate_failures do
        expect(object).to be_edge
        expect(object).not_to be_connection
      end

      it 'wraps the node type as an Object', :aggregate_failures do
        expect(object.node_type).to be_a(described_class)
        expect(object.node_type.name).to eq('Node')
      end
    end

    context 'with a connection over a scalar node' do
      let(:scalar_type) do
        Class.new(Types::BaseScalar) { graphql_name 'ScalarNode' }
      end

      subject(:object) { described_class.new(scalar_type.connection_type) }

      it 'wraps the node type as a Scalar' do
        expect(object.node_type).to be_a(Tooling::Graphql::Docs::Schema::Scalar)
      end
    end

    context 'with a connection over an enum node' do
      let(:enum_type) do
        Class.new(Types::BaseEnum) do
          graphql_name 'EnumNode'
          value 'A', 'A value.'
        end
      end

      subject(:object) { described_class.new(enum_type.connection_type) }

      it 'wraps the node type as an Enum' do
        expect(object.node_type).to be_a(Tooling::Graphql::Docs::Schema::Enum)
      end
    end

    context 'with a connection over an interface node' do
      let(:interface_type) do
        Module.new do
          include Types::BaseInterface
          graphql_name 'InterfaceNode'

          field :id, GraphQL::Types::ID, null: true
        end
      end

      subject(:object) { described_class.new(interface_type.connection_type) }

      it 'wraps the node type as TempUndocumented' do
        expect(object.node_type).to be_a(Tooling::Graphql::Docs::Schema::TempUndocumented)
      end
    end
  end
end
