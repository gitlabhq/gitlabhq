# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport do
  let(:project_id) { 321 }

  describe '.jira_issue_cache_key' do
    it 'returns cache key for Jira issue imported to given project' do
      expect(described_class.jira_issue_cache_key(project_id, 'DEMO-123')).to eq("jira-import/items-mapper/#{project_id}/issues/DEMO-123")
    end
  end

  describe '.already_imported_cache_key' do
    it 'returns cache key for already imported items' do
      expect(described_class.already_imported_cache_key(:issues, project_id)).to eq("jira-importer/already-imported/#{project_id}/issues")
    end
  end

  describe '.jira_issues_next_page_cache_key' do
    it 'returns cache key for next issues' do
      expect(described_class.jira_issues_next_page_cache_key(project_id)).to eq("jira-import/paginator/#{project_id}/issues")
    end
  end

  describe '.get_issues_next_start_at', :clean_gitlab_redis_cache do
    it 'returns zero when not defined' do
      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues")).to be nil
      expect(described_class.get_issues_next_start_at(project_id)).to eq(0)
    end

    it 'returns negative value for next issues to be imported starting point' do
      Gitlab::Cache::Import::Caching.write("jira-import/paginator/#{project_id}/issues", -10)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues")).to eq('-10')
      expect(described_class.get_issues_next_start_at(project_id)).to eq(-10)
    end

    it 'returns cached value for next issues to be imported starting point' do
      Gitlab::Cache::Import::Caching.write("jira-import/paginator/#{project_id}/issues", 10)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues")).to eq('10')
      expect(described_class.get_issues_next_start_at(project_id)).to eq(10)
    end
  end

  describe '.store_issues_next_started_at', :clean_gitlab_redis_cache do
    it 'stores nil value' do
      described_class.store_issues_next_started_at(project_id, nil)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues")).to eq ''
      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues").to_i).to eq(0)
    end

    it 'stores positive value' do
      described_class.store_issues_next_started_at(project_id, 10)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues").to_i).to eq(10)
    end

    it 'stores negative value' do
      described_class.store_issues_next_started_at(project_id, -10)

      expect(Gitlab::Cache::Import::Caching.read("jira-import/paginator/#{project_id}/issues").to_i).to eq(-10)
    end
  end
end
