# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe API::Helpers::SearchHelpers, feature_category: :global_search do
  describe '.global_search_scopes' do
    it 'for CE returns the expected scopes', unless: Gitlab.ee? do
      expect(described_class.global_search_scopes)
        .to match_array(%w[projects issues merge_requests milestones snippet_titles users])
    end

    it 'for EE returns the expected scopes', if: Gitlab.ee? do
      expect(described_class.global_search_scopes).to match_array(
        %w[wiki_blobs blobs commits notes projects issues merge_requests milestones snippet_titles users])
    end
  end

  describe '.group_search_scopes' do
    it 'for CE returns the expected scopes', unless: Gitlab.ee? do
      expect(described_class.group_search_scopes)
        .to match_array(%w[projects issues merge_requests milestones users])
    end

    it 'for EE returns the expected scopes', if: Gitlab.ee? do
      expect(described_class.group_search_scopes)
        .to match_array(%w[wiki_blobs blobs commits notes projects issues merge_requests milestones users])
    end
  end

  describe '.project_search_scopes' do
    it 'returns the expected scopes' do
      expect(described_class.project_search_scopes)
        .to match_array(%w[issues merge_requests milestones notes wiki_blobs commits blobs users])
    end
  end

  describe '.search_states' do
    it 'returns the expected states' do
      expect(described_class.search_states).to match_array(%w[all opened closed merged])
    end
  end

  describe '.search_param_keys' do
    it 'for CE returns the expected param keys', unless: Gitlab.ee? do
      expect(described_class.search_param_keys)
        .to match_array(%i[scope search state confidential num_context_lines search_type page per_page order_by sort])
    end

    it 'for EE returns the expected param keys', if: Gitlab.ee? do
      expect(described_class.search_param_keys).to match_array(
        %i[scope search state confidential num_context_lines search_type page per_page order_by sort fields])
    end
  end

  describe '.gitlab_search_mcp_params' do
    it 'returns search_param_keys with id', unless: Gitlab.ee? do
      expect(described_class.gitlab_search_mcp_params).to match_array(
        %i[scope search state confidential num_context_lines search_type page per_page order_by sort id])
    end

    it 'returns search_param_keys with id', if: Gitlab.ee? do
      expect(described_class.gitlab_search_mcp_params).to match_array(
        %i[scope search state confidential num_context_lines search_type page per_page order_by sort id fields])
    end
  end
end
