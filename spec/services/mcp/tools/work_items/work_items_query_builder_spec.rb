# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::WorkItemsQueryBuilder, feature_category: :mcp_server do
  describe '.build_query' do
    it 'defaults to the full projection with widget fragments', :aggregate_failures do
      query = described_class.build_query

      expect(query).to include('query GetWorkItemsFull(')
      expect(query).to include('author {')
      expect(query).to include('widgets {')
      expect(query).to include('... on WorkItemWidgetAssignees')
    end

    context 'with the compact projection' do
      it 'selects exactly the compact scalar row', :aggregate_failures do
        query = described_class.build_query(projection: :compact)

        expect(query).to include('query GetWorkItemsCompact(')
        expect(query).to include(<<~GRAPHQL.indent(8))
          id
          iid
          title
          state
          webUrl
          reference(full: true)
          createdAt
          updatedAt
          workItemType {
            id
            name
          }
        GRAPHQL
      end

      it 'contains no widget fragments', :aggregate_failures do
        query = described_class.build_query(projection: :compact)

        expect(query).not_to include('... on WorkItemWidget')
        expect(query).not_to include('widgets {')
        expect(query).not_to include('author {')
      end

      it 'keeps every filter variable and argument', :aggregate_failures do
        query = described_class.build_query(projection: :compact)

        described_class.filter_definitions.each do |filter|
          expect(query).to include("$#{filter[:key]}: #{filter[:type]}")
          expect(query).to include("#{filter[:key]}: $#{filter[:key]}")
        end
      end
    end
  end

  describe '.build_variables' do
    it 'returns the scope, hierarchy defaults, and default page size' do
      variables, unsupported = described_class.build_variables(full_path: 'group/project', filters: {})

      expect(variables).to eq(
        fullPath: 'group/project',
        includeDescendants: true,
        excludeProjects: false,
        excludeGroupWorkItems: false,
        firstPageSize: 20
      )
      expect(unsupported).to be_empty
    end

    it 'maps known filters into variables' do
      variables, _unsupported = described_class.build_variables(
        full_path: 'group/project',
        filters: { 'state' => 'opened', 'labelName' => %w[bug], 'authorUsername' => 'jane' }
      )

      expect(variables).to include(state: 'opened', labelName: %w[bug], authorUsername: 'jane')
    end

    it 'passes composite filters through with their nested keys' do
      variables, _unsupported = described_class.build_variables(
        full_path: 'group/project',
        filters: { 'not' => { 'authorUsername' => 'jane' } }
      )

      expect(variables[:not]).to eq('authorUsername' => 'jane')
    end

    it 'reports unknown filter keys instead of silently dropping them' do
      variables, unsupported = described_class.build_variables(
        full_path: 'group/project',
        filters: { 'bogusFilter' => 'x', 'state' => 'opened' }
      )

      expect(unsupported).to contain_exactly('bogusFilter')
      expect(variables).not_to have_key(:bogusFilter)
    end

    it 'lets a fullPath filter override the namespace scope' do
      variables, unsupported = described_class.build_variables(
        full_path: 'group/project',
        filters: { 'fullPath' => 'other/project' }
      )

      expect(variables[:fullPath]).to eq('other/project')
      expect(unsupported).to be_empty
    end

    it 'applies sort and explicit pagination' do
      variables, _unsupported = described_class.build_variables(
        full_path: 'group/project',
        filters: {},
        sort: 'UPDATED_DESC',
        first: 5,
        after: 'cursor123'
      )

      expect(variables).to include(sort: 'UPDATED_DESC', firstPageSize: 5, afterCursor: 'cursor123')
    end
  end
end
