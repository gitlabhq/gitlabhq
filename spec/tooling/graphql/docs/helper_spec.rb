# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/helper')
require Rails.root.join('tooling/graphql/docs/schema/enum')
require Rails.root.join('tooling/graphql/docs/schema/scalar')
require Rails.root.join('tooling/graphql/docs/schema/field')
require Rails.root.join('tooling/graphql/docs/schema/object')
require Rails.root.join('tooling/graphql/docs/schema/temp_undocumented')

RSpec.describe Tooling::Graphql::Docs::Helper, feature_category: :api do
  let(:helper) do
    Class.new do
      include Tooling::Graphql::Docs::Helper
    end.new
  end

  let_it_be(:mock_enum) do
    Class.new(Types::BaseEnum) do
      graphql_name 'MockEnum'

      value 'PLAIN', 'A plain value.'
      value 'EXPERIMENTAL', 'An experimental value.', experiment: { milestone: '16.0' }
      value 'DEPRECATED', 'A deprecated value.', deprecated: { milestone: '16.0', reason: 'Deprecated' }
    end
  end

  let(:enum_values) { mock_enum.enum_values }

  def value(name)
    Tooling::Graphql::Docs::Schema::EnumValue.new(
      enum_values.find { |enum_value| enum_value.graphql_name == name }
    )
  end

  describe '#name' do
    it 'returns the name in backticks' do
      expect(helper.name(value('PLAIN'))).to eq('`PLAIN`')
    end
  end

  describe '#sorted_by_name' do
    it 'sorts a collection by name' do
      sorted = helper.sorted_by_name([value('PLAIN'), value('DEPRECATED'), value('EXPERIMENTAL')])

      expect(sorted.map(&:name)).to eq(%w[DEPRECATED EXPERIMENTAL PLAIN])
    end
  end

  describe '#type' do
    let(:fake_graphql_type) { Struct.new(:graphql_name, :description) }
    let(:item_struct) { Struct.new(:type, :type_signature) }

    it 'returns a linked type signature for a known type' do
      scalar = Tooling::Graphql::Docs::Schema::Scalar.new(fake_graphql_type.new('String', nil))
      item = item_struct.new(scalar, 'String')

      expect(helper.type(item)).to eq('[`String`](scalars.md#string)')
    end

    it 'returns an unlinked type signature for a TempUndocumented type' do
      temp = Tooling::Graphql::Docs::Schema::TempUndocumented.new(fake_graphql_type.new('SomeObject', nil))
      item = item_struct.new(temp, 'SomeObject')

      expect(helper.type(item)).to eq('`SomeObject`')
    end
  end

  describe '#description' do
    it 'renders a plain description' do
      expect(helper.description(value('PLAIN'))).to eq('A plain value.')
    end

    it 'renders the experiment status and milestone for experimental items' do
      expect(helper.description(value('EXPERIMENTAL')))
        .to start_with('Status: Experiment. Introduced in GitLab 16.0.')
    end

    it 'renders the deprecation milestone for deprecated items' do
      expect(helper.description(value('DEPRECATED')))
        .to start_with('Deprecated in GitLab 16.0.')
    end
  end

  describe '#connection_summary' do
    let_it_be(:node_type) do
      Class.new(Types::BaseObject) do
        graphql_name 'Node'

        field :id, GraphQL::Types::ID, null: false
      end
    end

    let(:connection) do
      Tooling::Graphql::Docs::Schema::Object.new(node_type.connection_type)
    end

    context 'when the node type lives on another page' do
      before do
        helper.instance_variable_set(:@page, 'enums.md')
      end

      it 'links to the node type page' do
        expect(helper.connection_summary(connection))
          .to start_with('Paginated collection of [`Node`](objects.md#node).')
      end
    end

    context 'when the node type lives on the current page' do
      before do
        helper.instance_variable_set(:@page, 'objects.md')
      end

      it 'links to a bare anchor' do
        expect(helper.connection_summary(connection))
          .to start_with('Paginated collection of [`Node`](#node).')
      end
    end

    context 'when the node type has no docs page yet' do
      let(:interface_type) do
        Module.new do
          include Types::BaseInterface
          graphql_name 'InterfaceNode'

          field :id, GraphQL::Types::ID, null: true
        end
      end

      let(:connection) do
        Tooling::Graphql::Docs::Schema::Object.new(interface_type.connection_type)
      end

      it 'renders the node type unlinked' do
        expect(helper.connection_summary(connection))
          .to start_with('Paginated collection of `InterfaceNode`.')
      end
    end
  end

  describe '#extra_connection_fields' do
    let_it_be(:connection_type) do
      node_type = Class.new(Types::BaseObject) do
        graphql_name 'Node'

        field :id, GraphQL::Types::ID, null: false
      end

      Class.new(node_type.connection_type) do
        graphql_name 'NodeWithCountConnection'

        field :count, GraphQL::Types::Int, null: true, description: 'Count.'
      end
    end

    let(:connection) { Tooling::Graphql::Docs::Schema::Object.new(connection_type) }

    it 'drops the standard connection fields and keeps the rest' do
      names = helper.extra_connection_fields(connection).map(&:name)

      expect(names).to include('count')
      expect(names).not_to include('edges', 'nodes', 'pageInfo')
    end
  end

  describe '#field_description' do
    let_it_be(:mock_graphql_object) do
      node_type = Class.new(Types::BaseObject) do
        graphql_name 'DescNode'

        field :id, GraphQL::Types::ID, null: false
      end

      Class.new(Types::BaseObject) do
        field :plain, GraphQL::Types::String, null: true, description: 'A plain field.'
        field :items, node_type.connection_type, null: true, description: 'A connection field.'
        field :undescribed, node_type.connection_type, null: true
      end
    end

    def field(name)
      Tooling::Graphql::Docs::Schema::Field.new(mock_graphql_object.fields[name])
    end

    it 'returns the description unchanged for a plain field' do
      expect(helper.field_description(field('plain'))).to eq('A plain field.')
    end

    it 'appends the connection note for a connection field' do
      expect(helper.field_description(field('items')))
        .to eq("A connection field. #{helper.connection_note}")
    end

    it 'returns the connection note alone when the connection field has no description' do
      expect(helper.field_description(field('undescribed'))).to eq(helper.connection_note)
    end
  end

  describe '#documented_arguments?' do
    let_it_be(:mock_graphql_object) do
      node_type = Class.new(Types::BaseObject) do
        graphql_name 'ArgNode'

        field :id, GraphQL::Types::ID, null: false
      end

      Class.new(Types::BaseObject) do
        field :no_args, GraphQL::Types::String, null: true, description: 'No arguments.'

        field :pagination_only, node_type.connection_type, null: true, description: 'Pagination only.'

        field :with_arg, node_type.connection_type, null: true, description: 'With an argument.' do
          argument :search, GraphQL::Types::String, required: false, description: 'A search argument.'
        end
      end
    end

    def field(name)
      Tooling::Graphql::Docs::Schema::Field.new(mock_graphql_object.fields[name])
    end

    it 'is false for a field with no arguments' do
      expect(helper.documented_arguments?(field('noArgs'))).to be(false)
    end

    it 'is false for a connection field with only pagination arguments' do
      expect(helper.documented_arguments?(field('paginationOnly'))).to be(false)
    end

    it 'is true for a field with a non-pagination argument' do
      expect(helper.documented_arguments?(field('withArg'))).to be(true)
    end
  end
end
