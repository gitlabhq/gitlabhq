# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Scope, feature_category: :global_search do
  describe '.global' do
    context 'when all global search settings are enabled' do
      before do
        stub_application_setting(
          global_search_snippet_titles_enabled: true,
          global_search_issues_enabled: true,
          global_search_merge_requests_enabled: true,
          global_search_milestones_enabled: true,
          global_search_users_enabled: true
        )
      end

      it 'returns all global allowed scopes' do
        expect(described_class.global)
          .to match_array(described_class::ALWAYS_ALLOWED_SCOPES + described_class::GLOBAL_SCOPES)
      end
    end

    context 'when some global search settings are disabled' do
      before do
        stub_application_setting(global_search_issues_enabled: false, global_search_users_enabled: false)
      end

      it 'does not return those scopes' do
        expect(described_class.global).not_to include(%w[issues users])
      end
    end

    context 'when all global search settings are disabled' do
      before do
        stub_application_setting(
          global_search_snippet_titles_enabled: false,
          global_search_issues_enabled: false,
          global_search_merge_requests_enabled: false,
          global_search_users_enabled: false
        )
      end

      it 'returns only scopes which cannot be globally disabled' do
        expect(described_class.global).to match_array(described_class::ALWAYS_ALLOWED_SCOPES)
      end
    end
  end

  describe '.group' do
    it 'returns all global allowed scopes' do
      expect(described_class.group)
        .to match_array(described_class::ALWAYS_ALLOWED_SCOPES + described_class::GLOBAL_SCOPES)
    end

    context 'when all global search settings are disabled' do
      before do
        stub_application_setting(
          global_search_snippet_titles_enabled: false,
          global_search_issues_enabled: false,
          global_search_merge_requests_enabled: false,
          global_search_users_enabled: false
        )
      end

      it 'returns all global allowed scopes' do
        expect(described_class.group)
          .to match_array(described_class::ALWAYS_ALLOWED_SCOPES + described_class::GLOBAL_SCOPES)
      end
    end
  end

  describe '.project' do
    subject(:project) { described_class.project }

    it 'includes all global scopes plus project-specific scopes' do
      expect(described_class.project).to match_array(described_class::ALWAYS_ALLOWED_SCOPES +
        described_class::GLOBAL_SCOPES + described_class::PROJECT_SCOPES)
    end

    context 'when all global search settings are disabled' do
      before do
        stub_application_setting(
          global_search_snippet_titles_enabled: false,
          global_search_issues_enabled: false,
          global_search_merge_requests_enabled: false,
          global_search_users_enabled: false
        )
      end

      it 'includes all global scopes plus project-specific scopes' do
        expect(described_class.project).to match_array(described_class::ALWAYS_ALLOWED_SCOPES +
          described_class::GLOBAL_SCOPES + described_class::PROJECT_SCOPES)
      end
    end
  end
end
