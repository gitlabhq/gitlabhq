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

    interface_type = Module.new do
      include ::Types::BaseInterface
      graphql_name 'GraphQLInterface'

      field :interface_field, GraphQL::Types::Boolean, null: true
    end

    object_type = Class.new(::Types::BaseObject) do
      graphql_name 'GraphQLObject'

      implements interface_type

      field :object_field, GraphQL::Types::Boolean
    end

    union_type = Class.new(::Types::BaseUnion) do
      graphql_name 'GraphQLUnion'

      possible_types object_type
    end

    mutation_type = Class.new(::Mutations::BaseMutation) do
      graphql_name 'GraphQLMutation'

      field :result, GraphQL::Types::String, null: true, description: 'A result.'
    end

    Class.new(GraphQL::Schema) do
      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'

        field :enum_field, enum_type
        field :scalar_field, scalar_type
        field :object_field, object_type
        field :objects, object_type.connection_type, null: true, description: 'A connection.'
        field :interface_field, interface_type, null: true
        field :union_field, union_type, null: true
        field :input_field, scalar_type do
          argument :input, input_object_type, required: false
        end
      end)

      mutation(Class.new(::Types::BaseObject) do
        graphql_name 'Mutation'

        field :graphql_mutation, mutation: mutation_type
      end)

      subscription(Class.new(::Types::BaseObject) do
        graphql_name 'Subscription'

        field :object_updated, object_type, null: true, description: 'An update.'
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

    describe '@objects' do
      subject(:objects) { result.objects }

      it 'contains an array of object types' do
        expect(objects).to all(be_a(Tooling::Graphql::Docs::Schema::Object))
      end

      it 'contains the object type in the schema' do
        expect(objects.map(&:name)).to include('GraphQLObject')
      end

      it 'excludes the root query, mutation, and subscription types' do
        expect(objects.map(&:name)).not_to include('Query', 'Mutation', 'Subscription')
      end

      it 'excludes mutation payload types' do
        expect(objects.map(&:name)).not_to include('GraphQLMutationPayload')
      end

      it 'excludes standard edge types' do
        expect(objects.map(&:name)).not_to include('GraphQLObjectEdge')
      end

      it 'includes connection types' do
        expect(objects.map(&:name)).to include('GraphQLObjectConnection')
      end
    end

    describe '@interfaces' do
      subject(:interfaces) { result.interfaces }

      it 'contains an array of interface types' do
        expect(interfaces).to all(be_a(Tooling::Graphql::Docs::Schema::Interface))
      end

      it 'contains the interface type in the schema' do
        expect(interfaces.map(&:name)).to include('GraphQLInterface')
      end

      it 'resolves the interface implementations' do
        interface = interfaces.find { |type| type.name == 'GraphQLInterface' }

        expect(interface.implementations.map(&:name)).to include('GraphQLObject')
      end
    end

    describe '@unions' do
      subject(:unions) { result.unions }

      it 'contains an array of union types' do
        expect(unions).to all(be_a(Tooling::Graphql::Docs::Schema::Union))
      end

      it 'contains the union type in the schema' do
        expect(unions.map(&:name)).to contain_exactly('GraphQLUnion')
      end

      it 'resolves the union members' do
        expect(unions.first.members.map(&:name)).to contain_exactly('GraphQLObject')
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
