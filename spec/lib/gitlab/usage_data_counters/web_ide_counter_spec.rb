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
end
