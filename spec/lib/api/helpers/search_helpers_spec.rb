# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe API::Helpers::SearchHelpers, feature_category: :global_search do
  describe '.global_search_scopes' do
    it 'for CE returns the expected scopes', unless: Gitlab.ee? do
      expect(described_class.global_search_scopes)
        .to match_array(%w[projects issues work_items merge_requests milestones snippet_titles users])
    end

    it 'for EE returns the expected scopes', if: Gitlab.ee? do
      expect(described_class.global_search_scopes).to match_array(
        %w[wiki_blobs blobs commits notes projects issues work_items merge_requests milestones snippet_titles users])
    end
  end

  describe '.group_search_scopes' do
    it 'for CE returns the expected scopes', unless: Gitlab.ee? do
      expect(described_class.group_search_scopes)
        .to match_array(%w[projects issues work_items merge_requests milestones users])
    end

    it 'for EE returns the expected scopes', if: Gitlab.ee? do
      expect(described_class.group_search_scopes)
        .to match_array(%w[wiki_blobs blobs commits notes projects issues work_items merge_requests milestones users])
    end
  end

  describe '.project_search_scopes' do
    it 'returns the expected scopes' do
      expect(described_class.project_search_scopes)
        .to match_array(%w[issues work_items merge_requests milestones notes wiki_blobs commits blobs users])
    end
  end

  describe '.search_states' do
    it 'returns the expected states' do
      expect(described_class.search_states).to match_array(%w[all opened closed merged])
    end
  end

  describe '.work_item_type_filter_desc' do
    it 'for CE returns description with CE types', unless: Gitlab.ee? do
      expect(described_class.work_item_type_filter_desc).to eq(
        'Filter work items by type. Only applies to work_items scope. ' \
          'Available types: issue, task, incident, ticket.'
      )
    end

    it 'for EE returns description with EE types', if: Gitlab.ee? do
      expect(described_class.work_item_type_filter_desc).to eq(
        'Filter work items by type. Only applies to work_items scope. ' \
          'Available types: issue, task, epic, incident, test_case, requirement, objective, key_result, ticket.'
      )
    end
  end

  describe '.search_param_keys' do
    it 'for CE returns the expected param keys', unless: Gitlab.ee? do
      expect(described_class.search_param_keys).to match_array(
        %i[confidential include_archived order_by page per_page scope search search_type sort state type]
      )
    end

    it 'for EE returns the expected param keys', if: Gitlab.ee? do
      expect(described_class.search_param_keys).to match_array(
        %i[
          confidential exclude_forks fields include_archived num_context_lines order_by page per_page regex scope search
          search_type sort state type
        ]
      )
    end
  end

  describe '.gitlab_search_mcp_params' do
    it 'returns search_param_keys with id', unless: Gitlab.ee? do
      expect(described_class.gitlab_search_mcp_params).to match_array(
        %i[
          confidential id include_archived order_by page per_page scope search search_type sort state type
        ]
      )
    end

    it 'returns search_param_keys with id', if: Gitlab.ee? do
      expect(described_class.gitlab_search_mcp_params).to match_array(
        %i[
          confidential exclude_forks fields id include_archived num_context_lines order_by page per_page regex scope
          search search_type sort state type
        ]
      )
    end
  end
end
