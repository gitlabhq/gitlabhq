# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('tooling/graphql/docs/schema/item')
require Rails.root.join('tooling/graphql/docs/schema/enum')
require Rails.root.join('tooling/graphql/docs/schema/input_object')
require Rails.root.join('tooling/graphql/docs/schema/scalar')
require Rails.root.join('tooling/graphql/docs/schema/temp_undocumented')
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

    context 'with a type that has no docs page yet' do
      let(:object_type) do
        Class.new(Types::BaseObject) do
          graphql_name 'Object'
          field :id, GraphQL::Types::ID, null: true, description: 'ID.'
        end
      end

      subject(:typeable) { typeable_for(object_type) }

      it 'falls back to TempUndocumented', :aggregate_failures do
        expect(typeable.type).to be_a(Tooling::Graphql::Docs::Schema::TempUndocumented)
        expect(typeable.type_signature).to eq('Object')
      end
    end
  end
end
