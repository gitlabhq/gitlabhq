# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Docs::Renderer do
  describe '#contents' do
    # Returns a Schema that uses the given `type`
    def mock_schema(type)
      query_type = Class.new(Types::BaseObject) do
        graphql_name 'QueryType'

        field :foo, type, null: true
      end

      GraphQL::Schema.define(query: query_type)
    end

    let_it_be(:template) { Rails.root.join('lib/gitlab/graphql/docs/templates/', 'default.md.haml') }

    subject(:contents) do
      described_class.new(
        mock_schema(type).graphql_definition,
        output_dir: nil,
        template: template
      ).contents
    end

    context 'A type with a field with a [Array] return type' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'ArrayTest'

          field :foo, [GraphQL::STRING_TYPE], null: false, description: 'A description'
        end
      end

      specify do
        expectation = <<~DOC
          ### ArrayTest

          | Field | Type | Description |
          | ----- | ---- | ----------- |
          | `foo` | String! => Array | A description |
        DOC

        is_expected.to include(expectation)
      end
    end

    context 'A type with fields defined in reverse alphabetical order' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'OrderingTest'

          field :foo, GraphQL::STRING_TYPE, null: false, description: 'A description of foo field'
          field :bar, GraphQL::STRING_TYPE, null: false, description: 'A description of bar field'
        end
      end

      specify do
        expectation = <<~DOC
          ### OrderingTest

          | Field | Type | Description |
          | ----- | ---- | ----------- |
          | `bar` | String! | A description of bar field |
          | `foo` | String! | A description of foo field |
        DOC

        is_expected.to include(expectation)
      end
    end

    context 'A type with a deprecated field' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'DeprecatedTest'

          field :foo, GraphQL::STRING_TYPE, null: false, deprecated: { reason: 'This is deprecated', milestone: '1.10' }, description: 'A description'
        end
      end

      specify do
        expectation = <<~DOC
          ### DeprecatedTest

          | Field | Type | Description |
          | ----- | ---- | ----------- |
          | `foo` **{warning-solid}** | String! | **Deprecated:** This is deprecated. Deprecated in 1.10 |
        DOC

        is_expected.to include(expectation)
      end
    end

    context 'A type with an emum field' do
      let(:type) do
        enum_type = Class.new(Types::BaseEnum) do
          graphql_name 'MyEnum'

          value 'BAZ', description: 'A description of BAZ'
          value 'BAR', description: 'A description of BAR', deprecated: { reason: 'This is deprecated', milestone: '1.10' }
        end

        Class.new(Types::BaseObject) do
          graphql_name 'EnumTest'

          field :foo, enum_type, null: false, description: 'A description of foo field'
        end
      end

      specify do
        expectation = <<~DOC
          ### MyEnum

          | Value | Description |
          | ----- | ----------- |
          | `BAR` **{warning-solid}** | **Deprecated:** This is deprecated. Deprecated in 1.10 |
          | `BAZ` | A description of BAZ |
        DOC

        is_expected.to include(expectation)
      end
    end
  end
end
