# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/item')
require Rails.root.join('tooling/graphql/docs/schema/enum')
require Rails.root.join('tooling/graphql/docs/schema/input_object')
require Rails.root.join('tooling/graphql/docs/schema/object')
require Rails.root.join('tooling/graphql/docs/schema/scalar')
require Rails.root.join('tooling/graphql/docs/schema/interface')
require Rails.root.join('tooling/graphql/docs/schema/union')
require Rails.root.join('tooling/graphql/docs/schema/concerns/typeable')

RSpec.describe Tooling::Graphql::Docs::Schema::Typeable, feature_category: :api do
  let(:includer_class) do
    Class.new(Tooling::Graphql::Docs::Schema::Item) do
      include Tooling::Graphql::Docs::Schema::Typeable
    end
  end

  let(:typeable_struct) { Struct.new(:type, :graphql_name, :description) }

  def typeable_for(graphql_type)
    includer_class.new(typeable_struct.new(graphql_type, 'item', nil))
  end

  describe '#type and #type_signature' do
    context 'with a scalar type' do
      subject(:typeable) { typeable_for(GraphQL::Types::String) }

      it 'identifies a Scalar', :aggregate_failures do
        expect(typeable.type).to be_a(Tooling::Graphql::Docs::Schema::Scalar)
        expect(typeable.type_signature).to eq('String')
      end
    end

    context 'with an enum type' do
      let(:enum_type) do
        Class.new(Types::BaseEnum) do
          graphql_name 'Enum'
          value 'A', 'A value.'
        end
      end

      subject(:typeable) { typeable_for(enum_type) }

      it 'identifies an Enum', :aggregate_failures do
        expect(typeable.type).to be_a(Tooling::Graphql::Docs::Schema::Enum)
        expect(typeable.type_signature).to eq('Enum')
      end
    end

    context 'with an input object type' do
      let(:input_object_type) do
        Class.new(Types::BaseInputObject) do
          graphql_name 'InputObject'
          argument :x, GraphQL::Types::String, required: false, description: 'X.'
        end
      end

      subject(:typeable) { typeable_for(input_object_type) }

      it 'identifies an InputObject without loading its arguments', :aggregate_failures do
        expect(typeable.type).to be_a(Tooling::Graphql::Docs::Schema::InputObject)
        expect(typeable.type.arguments).to be_nil
        expect(typeable.type_signature).to eq('InputObject')
      end
    end

    context 'with an object type' do
      let(:object_type) do
        Class.new(Types::BaseObject) do
          graphql_name 'Object'
          field :id, GraphQL::Types::ID, null: true, description: 'ID.'
        end
      end

      subject(:typeable) { typeable_for(object_type) }

      it 'identifies an Object without loading its fields', :aggregate_failures do
        expect(typeable.type).to be_a(Tooling::Graphql::Docs::Schema::Object)
        expect(typeable.type.fields).to be_nil
        expect(typeable.type_signature).to eq('Object')
      end
    end

    context 'with a wrapped object type' do
      let(:object_type) do
        Class.new(Types::BaseObject) do
          graphql_name 'Object'
          field :id, GraphQL::Types::ID, null: true, description: 'ID.'
        end
      end

      subject(:typeable) { typeable_for(object_type.to_non_null_type) }

      it 'unwraps to identify an Object', :aggregate_failures do
        expect(typeable.type).to be_a(Tooling::Graphql::Docs::Schema::Object)
        expect(typeable.type_signature).to eq('Object!')
      end
    end

    context 'with an interface type' do
      let(:interface_type) do
        Module.new do
          include Types::BaseInterface
          graphql_name 'Interface'
          field :id, GraphQL::Types::ID, null: true, description: 'ID.'
        end
      end

      subject(:typeable) { typeable_for(interface_type) }

      it 'identifies an Interface without loading its fields', :aggregate_failures do
        expect(typeable.type).to be_a(Tooling::Graphql::Docs::Schema::Interface)
        expect(typeable.type.fields).to be_nil
        expect(typeable.type_signature).to eq('Interface')
      end
    end

    context 'with a union type' do
      let(:member_type) do
        Class.new(Types::BaseObject) do
          graphql_name 'Member'
          field :id, GraphQL::Types::ID, null: true, description: 'ID.'
        end
      end

      let(:union_type) do
        member = member_type

        Class.new(Types::BaseUnion) do
          graphql_name 'Union'
          possible_types member
        end
      end

      subject(:typeable) { typeable_for(union_type) }

      it 'identifies a Union', :aggregate_failures do
        expect(typeable.type).to be_a(Tooling::Graphql::Docs::Schema::Union)
        expect(typeable.type_signature).to eq('Union')
      end
    end
  end
end
