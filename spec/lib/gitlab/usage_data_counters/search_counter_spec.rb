# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::SearchCounter, :clean_gitlab_redis_shared_state do
  it 'increments counter and return the total count' do
    expect(described_class.total_navbar_searches_count).to eq(0)

    2.times { described_class.increment_navbar_searches_count }

    expect(described_class.total_navbar_searches_count).to eq(2)
  end
end
