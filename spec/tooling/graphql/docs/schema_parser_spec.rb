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

    Class.new(GraphQL::Schema) do
      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'

        field :enum_field, enum_type
      end)
    end
  end

  describe '#execute' do
    subject(:result) { described_class.new(schema).execute }

    describe '@enums' do
      subject(:enums) { result.enums }

      it 'contains an array of enum types' do
        expect(enums).to all(be_a(Tooling::Graphql::Docs::Schema::Enum))
      end

      it 'contains all enum types in the schema' do
        expect(enums.map(&:name)).to contain_exactly('GraphQLEnum')
      end
    end
  end
end
