# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::RedisMetric, :clean_gitlab_redis_shared_state do
  before do
    4.times do
      Gitlab::UsageDataCounters::SourceCodeCounter.count(:pushes)
    end
  end

  let(:expected_value) { 4 }

  it_behaves_like 'a correct instrumented metric value', { options: { event: 'pushes', counter_class: 'SourceCodeCounter' } }

  it 'raises an exception if event option is not present' do
    expect { described_class.new(counter_class: 'SourceCodeCounter') }.to raise_error(ArgumentError)
  end

  it 'raises an exception if counter_class option is not present' do
    expect { described_class.new(event: 'pushes') }.to raise_error(ArgumentError)
  end
end
