# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Graphql::VersionFilter::FutureFieldFilter, feature_category: :shared do
  include VersionMilestoneHelpers

  let(:query) do
    format(<<~GRAPHQL, version: version)
    query fetchData {
      name
      futureField @gl_introduced(version: "%{version}")
    }
    GRAPHQL
  end

  let(:filter) { described_class.new(GraphQL.parse(query)) }
  let(:filtered_document) { filter.visit }

  def filtered_query
    filtered_document.to_query_string.encode('UTF-8').strip
  end

  context 'when version is in a past milestone' do
    let(:version) { previous_milestone(Gitlab.version_info).to_s }

    it 'does not remove any fields' do
      expect(filtered_query).to eq(query.strip)
      expect(filter.contain_future_fields).to be(false)
    end
  end

  context 'when version is in the current milestone' do
    let(:version) { Gitlab.version_info.to_s }

    it 'removes the field and collects its name' do
      expect(filtered_query).to eq <<~GRAPHQL.strip
      query fetchData {
        name
      }
      GRAPHQL

      expect(filter.future_field_names).to contain_exactly('futureField')
    end
  end

  context 'when version is a later patch of the current milestone' do
    let(:version) do
      current = Gitlab.version_info
      Gitlab::VersionInfo
        .new(current.major, current.minor, current.patch + 1)
        .to_s
    end

    it 'removes the field' do
      expect(filtered_query).to eq <<~GRAPHQL.strip
      query fetchData {
        name
      }
      GRAPHQL

      expect(filter.future_field_names).to contain_exactly('futureField')
    end
  end

  context 'when version is in a future milestone' do
    let(:version) do
      current = Gitlab.version_info
      Gitlab::VersionInfo
        .new(current.major, current.minor + 1, 0)
        .to_s
    end

    it 'removes the field' do
      expect(filtered_query).to eq <<~GRAPHQL.strip
      query fetchData {
        name
      }
      GRAPHQL

      expect(filter.future_field_names).to contain_exactly('futureField')
    end
  end

  context 'when version is not a valid version string' do
    let(:version) { 'banana' }

    it 'does not remove any fields' do
      expect(filtered_query).to eq(query.strip)
      expect(filter.contain_future_fields).to be(false)
    end
  end

  context 'when version is not a string literal' do
    let(:query) do
      <<~GRAPHQL
      query fetchData {
        name
        futureField @gl_introduced(version: 123)
      }
      GRAPHQL
    end

    it 'does not remove any fields' do
      expect(filtered_query).to eq(query.strip)
      expect(filter.contain_future_fields).to be(false)
    end
  end

  context 'when the stripped node has a subtree' do
    let(:version) { Gitlab.version_info.to_s }
    let(:query) do
      format(<<~GRAPHQL, version: version)
      query fetchData($id: ID!, $term: String) {
        name
        futureField @gl_introduced(version: "%{version}") {
          __typename
          childField(id: $id) {
            ...sharedFields
          }
        }
      }

      fragment sharedFields on Item {
        title(term: $term)
        ...nestedFields
      }

      fragment nestedFields on Item {
        description
      }
      GRAPHQL
    end

    before do
      filtered_document
    end

    it 'collects every field name in the stripped subtree' do
      expect(filter.future_field_names).to contain_exactly('futureField', 'childField')
    end

    it 'suppresses unused errors for its variables and fragments' do
      variable_error = GraphQL::StaticValidation::VariablesAreUsedAndDefinedError.new(
        'Variable $id is declared by fetchData but not used',
        name: 'id', error_type: 'variableNotUsed'
      )
      transitive_variable_error = GraphQL::StaticValidation::VariablesAreUsedAndDefinedError.new(
        'Variable $term is declared by fetchData but not used',
        name: 'term', error_type: 'variableNotUsed'
      )
      fragment_definition = filtered_document.definitions.find do |definition|
        definition.is_a?(GraphQL::Language::Nodes::FragmentDefinition) && definition.name == 'nestedFields'
      end
      fragment_error = GraphQL::StaticValidation::FragmentsAreUsedError.new(
        'Fragment nestedFields was defined, but not used',
        nodes: fragment_definition, fragment: 'nestedFields'
      )

      expect(filter.suppress?(variable_error)).to be(true)
      expect(filter.suppress?(transitive_variable_error)).to be(true)
      expect(filter.suppress?(fragment_error)).to be(true)
    end

    it 'does not suppress unused errors for unrelated variables and fragments' do
      variable_error = GraphQL::StaticValidation::VariablesAreUsedAndDefinedError.new(
        'Variable $other is declared by fetchData but not used',
        name: 'other', error_type: 'variableNotUsed'
      )
      undefined_variable_error = GraphQL::StaticValidation::VariablesAreUsedAndDefinedError.new(
        'Variable $id is used by fetchData but not declared',
        name: 'id', error_type: 'variableNotDefined'
      )
      fragment_error = GraphQL::StaticValidation::FragmentsAreUsedError.new(
        'Fragment otherFragment was defined, but not used',
        nodes: [], fragment: 'otherFragment'
      )

      expect(filter.suppress?(variable_error)).to be(false)
      expect(filter.suppress?(undefined_variable_error)).to be(false)
      expect(filter.suppress?(fragment_error)).to be(false)
    end
  end

  context 'when stripping empties a selection set' do
    let(:version) { Gitlab.version_info.to_s }
    let(:query) do
      format(<<~GRAPHQL, version: version)
      query fetchData {
        futureField @gl_introduced(version: "%{version}")
      }
      GRAPHQL
    end

    it 'suppresses the selection error of the emptied parent only' do
      emptied_operation = filtered_document.definitions.first
      selection_error = GraphQL::StaticValidation::FieldsHaveAppropriateSelectionsError.new(
        "Field must have selections (query 'fetchData' returns Query but has no selections)",
        nodes: emptied_operation, node_name: "query 'fetchData'"
      )
      unrelated_error = GraphQL::StaticValidation::FieldsHaveAppropriateSelectionsError.new(
        "Field must have selections (field 'project' returns Project but has no selections)",
        nodes: GraphQL.parse('{ project }').definitions.first.selections.first,
        node_name: "field 'project'"
      )

      expect(filter.suppress?(selection_error)).to be(true)
      expect(filter.suppress?(unrelated_error)).to be(false)
    end
  end
end
