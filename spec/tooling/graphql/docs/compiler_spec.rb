# frozen_string_literal: true

require 'spec_helper'

require_relative Rails.root.join('tooling/graphql/docs/compiler')

RSpec.describe Tooling::Graphql::Docs::Compiler, feature_category: :api do
  let_it_be(:mock_schema) do
    spec_scalar = Class.new(::Types::BaseScalar) do
      graphql_name 'SpecScalar'
      description 'A spec scalar.'
    end

    spec_enum = Class.new(::Types::BaseEnum) do
      graphql_name 'SpecEnum'
      description 'A spec enum.'

      value 'PLAIN', 'A plain value.'
      value 'EXPERIMENTAL', 'An experimental value.', experiment: { milestone: '2.0' }
      value 'DEPRECATED', 'A deprecated value.', deprecated: { milestone: '1.0', reason: 'Use PLAIN instead' }
    end

    Class.new(GraphQL::Schema) do
      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'

        field :scalar_field, spec_scalar
        field :enum_field, spec_enum
      end)
    end
  end

  subject(:pages) { described_class.new(schema: mock_schema).execute }

  def page(filename)
    pages.find { |compiled_doc| compiled_doc.filename.to_s.end_with?(filename) }
  end

  describe 'the scalars page' do
    subject(:doc) { page('scalars.md').doc }

    it 'renders a heading and description for each scalar' do
      expect(doc).to include(
        <<~MD
          ## `SpecScalar`

          A spec scalar.
        MD
      )
    end

    it 'does not include introspection types' do
      expect(doc).not_to include('__')
    end
  end

  describe 'the enums page' do
    subject(:doc) { page('enums.md').doc }

    it 'renders a heading and values table for the enum' do
      expect(doc).to include(
        <<~MD
          ## `SpecEnum`

          A spec enum.

          | Value | Description |
          | ----- | ----------- |
        MD
      )
    end

    it 'renders a plain value' do
      expect(doc).to include('| `PLAIN` | A plain value. |')
    end

    it 'renders a deprecated value with its milestone and reason' do
      expect(doc).to include('| `DEPRECATED` | Deprecated in GitLab 1.0. Use PLAIN instead. |')
    end

    it 'renders an experimental value with its status and milestone' do
      expect(doc).to include(
        '| `EXPERIMENTAL` | Status: Experiment. Introduced in GitLab 2.0.<br/><br/>An experimental value. |'
      )
    end

    it 'lists values in alphabetical order' do
      expect(doc.scan(/^\| `(\w+)` \|/).flatten).to eq(%w[DEPRECATED EXPERIMENTAL PLAIN])
    end
  end
end
