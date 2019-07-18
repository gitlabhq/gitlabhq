# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::WebIdeCounter, :clean_gitlab_redis_shared_state do
  describe '.increment_commits_count' do
    it 'increments the web ide commits counter by 1' do
      expect do
        described_class.increment_commits_count
      end.to change { described_class.total_commits_count }.by(1)
    end
  end

  describe '.total_commits_count' do
    it 'returns the total amount of web ide commits' do
      2.times { described_class.increment_commits_count }

      expect(described_class.total_commits_count).to eq(2)
    end
  end
end
