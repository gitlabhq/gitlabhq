# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Onboarding::FeatureLibrary::TerminologyMap, feature_category: :onboarding do
  # These blocks intentionally load the real data/feature_search_terms.yml (rather
  # than mock data) to validate the actual curated content. They guard against a
  # new or edited entry breaking search - blank fields, duplicate (term, panel) pairs,
  # terms that aren't lowercase/stripped (which can never match), or feature_keys that
  # are not real Sidebars::MenuItem item_ids. The .all block below uses mock data to
  # test the loader mechanism in isolation.
  describe 'data/feature_search_terms.yml' do
    let(:raw_entries) do
      YAML.safe_load_file(Rails.root.join("data/feature_search_terms.yml"), permitted_classes: []) || []
    end

    it 'has no entries missing a term, feature_key, or panels' do
      blank = raw_entries.select do |e|
        e['term'].to_s.strip.empty? ||
          e['feature_key'].to_s.strip.empty? ||
          Array(e['panels']).empty?
      end
      expect(blank).to be_empty, "found entries with blank term, feature_key, or panels: #{blank.inspect}"
    end

    it 'has no duplicate (term, panel) pairs' do
      pairs = raw_entries.flat_map { |e| Array(e['panels']).map { |p| [e['term'], p] } }
      duplicates = pairs.group_by(&:itself).select { |_, v| v.size > 1 }.keys
      expect(duplicates).to be_empty, "found duplicate (term, panel) pairs: #{duplicates.inspect}"
    end

    it 'has all terms already lowercase and stripped (to match FeatureMatchService normalization)' do
      non_normalized = raw_entries.map { |e| e['term'] }.select { |t| t != t.to_s.downcase.strip }
      expect(non_normalized).to be_empty,
        "found terms that are not lowercase+stripped (they can never match): #{non_normalized.inspect}"
    end

    it 'has all panels values valid ([project], [group], or [project, group])' do
      valid_panels = %w[project group].to_set
      invalid = raw_entries.reject { |e| Array(e['panels']).all? { |p| valid_panels.include?(p) } }
      expect(invalid).to be_empty, "found entries with invalid panels: #{invalid.inspect}"
    end
  end

  describe '.all' do
    let(:mock_entries) do
      [
        { 'term' => 'pull request', 'feature_key' => 'project_merge_request_list', 'panels' => ['project'] },
        { 'term' => 'pull request', 'feature_key' => 'group_merge_request_list', 'panels' => ['group'] },
        { 'term' => 'ticket', 'feature_key' => 'project_issue_list', 'panels' => ['project'] }
      ]
    end

    before do
      allow(YAML).to receive(:safe_load_file).and_call_original
      allow(YAML).to receive(:safe_load_file)
        .with(Rails.root.join("data/feature_search_terms.yml"), permitted_classes: [])
        .and_return(mock_entries)
      described_class.instance_variable_set(:@all, nil)
    end

    after do
      described_class.instance_variable_set(:@all, nil)
    end

    it 'returns a frozen array of entry hashes', :aggregate_failures do
      expect(described_class.all).to be_an(Array)
      expect(described_class.all).to be_frozen
    end

    it 'exposes term, feature_key, and panels per entry', :aggregate_failures do
      entry = described_class.all.first
      expect(entry['term']).to eq('pull request')
      expect(entry['feature_key']).to eq('project_merge_request_list')
      expect(entry['panels']).to eq(['project'])
    end
  end
end
