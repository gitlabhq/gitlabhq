# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::RedisHLLMetric, :clean_gitlab_redis_shared_state do
  before do
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 1, time: 1.week.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 1, time: 2.weeks.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 2, time: 2.weeks.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 2, time: 2.months.ago)
  end

  context 'for 28d' do
    let(:expected_value) { 2 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', options: { events: ['i_quickactions_approve'] } }
  end

  context 'for 7d' do
    let(:expected_value) { 1 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: '7d', options: { events: ['i_quickactions_approve'] } }
  end

  it 'raise exception if events options is not present' do
    expect { described_class.new(time_frame: '28d') }.to raise_error(ArgumentError)
  end
end
