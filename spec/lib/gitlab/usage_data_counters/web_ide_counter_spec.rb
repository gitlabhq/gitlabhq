# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::WebIdeCounter, :clean_gitlab_redis_shared_state do
  shared_examples 'counter examples' do
    it 'increments counter and return the total count' do
      expect(described_class.public_send(total_counter_method)).to eq(0)

      2.times { described_class.public_send(increment_counter_method) }

      expect(described_class.public_send(total_counter_method)).to eq(2)
    end
  end

  describe 'commits counter' do
    let(:increment_counter_method) { :increment_commits_count }
    let(:total_counter_method) { :total_commits_count }

    it_behaves_like 'counter examples'
  end

  describe 'merge requests counter' do
    let(:increment_counter_method) { :increment_merge_requests_count }
    let(:total_counter_method) { :total_merge_requests_count }

    it_behaves_like 'counter examples'
  end

  describe 'views counter' do
    let(:increment_counter_method) { :increment_views_count }
    let(:total_counter_method) { :total_views_count }

    it_behaves_like 'counter examples'
  end

  describe 'previews counter' do
    let(:setting_enabled) { true }

    before do
      stub_application_setting(web_ide_clientside_preview_enabled: setting_enabled)
    end

    context 'when web ide clientside preview is enabled' do
      let(:increment_counter_method) { :increment_previews_count }
      let(:total_counter_method) { :total_previews_count }

      it_behaves_like 'counter examples'
    end

    context 'when web ide clientside preview is not enabled' do
      let(:setting_enabled) { false }

      it 'does not increment the counter' do
        expect(described_class.total_previews_count).to eq(0)

        2.times { described_class.increment_previews_count }

        expect(described_class.total_previews_count).to eq(0)
      end
    end
  end

  describe '.totals' do
    commits = 5
    merge_requests = 3
    views = 2
    previews = 4

    before do
      stub_application_setting(web_ide_clientside_preview_enabled: true)

      commits.times { described_class.increment_commits_count }
      merge_requests.times { described_class.increment_merge_requests_count }
      views.times { described_class.increment_views_count }
      previews.times { described_class.increment_previews_count }
    end

    it 'can report all totals' do
      expect(described_class.totals).to include(
        web_ide_commits: commits,
        web_ide_views: views,
        web_ide_merge_requests: merge_requests,
        web_ide_previews: previews
      )
    end
  end
end
