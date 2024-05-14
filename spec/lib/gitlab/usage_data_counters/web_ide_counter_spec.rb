# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::WebIdeCounter, :clean_gitlab_redis_shared_state do
  shared_examples 'counter examples' do |event|
    it 'increments counter and return the total count' do
      expect(described_class.public_send(:total_count, event)).to eq(0)

      2.times { described_class.public_send(:"increment_#{event}_count") }

      redis_key = "web_ide_#{event}_count".upcase
      expect(described_class.public_send(:total_count, redis_key)).to eq(2)
    end
  end

  describe 'commits counter' do
    it_behaves_like 'counter examples', 'commits'
  end

  describe 'merge requests counter' do
    it_behaves_like 'counter examples', 'merge_requests'
  end

  describe 'terminals counter' do
    it_behaves_like 'counter examples', 'terminals'
  end

  describe 'pipelines counter' do
    it_behaves_like 'counter examples', 'pipelines'
  end

  describe '.totals' do
    commits = 5
    merge_requests = 3
    terminals = 1
    pipelines = 2

    before do
      commits.times { described_class.increment_commits_count }
      merge_requests.times { described_class.increment_merge_requests_count }
      terminals.times { described_class.increment_terminals_count }
      pipelines.times { described_class.increment_pipelines_count }
    end

    it 'can report all totals' do
      expect(described_class.totals).to include(
        web_ide_commits: commits,
        web_ide_merge_requests: merge_requests,
        web_ide_terminals: terminals
      )
    end
  end
end
