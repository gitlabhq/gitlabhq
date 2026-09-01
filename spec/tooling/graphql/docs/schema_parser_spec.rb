# frozen_string_literal: true

require 'spec_helper'

require_relative Rails.root.join('tooling/graphql/docs/schema_parser')

RSpec.describe Tooling::Graphql::Docs::SchemaParser, feature_category: :api do
  let_it_be(:schema) do
    enum_type = Class.new(::Types::BaseEnum) do
      graphql_name 'GraphQLEnum'

      value 'FOO', 'Foo value.'
      value 'BAR', 'Bar value.'
    end

    scalar_type = Class.new(::Types::BaseScalar) do
      graphql_name 'GraphQLScalar'
    end

    input_object_type = Class.new(::Types::BaseInputObject) do
      graphql_name 'GraphQLInputObject'

      argument :my_arg, GraphQL::Types::String, required: false
    end

    Class.new(GraphQL::Schema) do
      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'

        field :enum_field, enum_type
        field :scalar_field, scalar_type
        field :input_field, scalar_type do
          argument :input, input_object_type, required: false
        end
      end)
    end
  end

  describe '#execute' do
    subject(:result) { described_class.new(schema).execute }

    describe '@directives' do
      subject(:directives) { result.directives }

      it 'contains an array of directive types' do
        expect(directives).to all(be_a(Tooling::Graphql::Docs::Schema::Directive))
      end

      it 'contains the built-in directives in the schema' do
        expect(directives.map(&:name)).to include('include', 'skip')
      end
    end

    describe '@enums' do
      subject(:enums) { result.enums }

      it 'contains an array of enum types' do
        expect(enums).to all(be_a(Tooling::Graphql::Docs::Schema::Enum))
      end

      it 'contains all enum types in the schema' do
        expect(enums.map(&:name)).to contain_exactly('GraphQLEnum')
      end
    end

    describe '@input_objects' do
      subject(:input_objects) { result.input_objects }

      it 'contains an array of input object types' do
        expect(input_objects).to all(be_a(Tooling::Graphql::Docs::Schema::InputObject))
      end

      it 'contains the input object type in the schema' do
        expect(input_objects.map(&:name)).to include('GraphQLInputObject')
      end
    end

    describe '@scalars' do
      subject(:scalars) { result.scalars }

      it 'contains an array of scalar types' do
        expect(scalars).to all(be_a(Tooling::Graphql::Docs::Schema::Scalar))
      end

      it 'contains the custom scalar type in the schema' do
        expect(scalars.map(&:name)).to include('GraphQLScalar')
      end
    end
  end
end
