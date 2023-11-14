# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::RedisMetric, :clean_gitlab_redis_shared_state,
  feature_category: :service_ping do
  before do
    4.times do
      Gitlab::UsageDataCounters::SourceCodeCounter.count(:pushes)
    end
  end

  let(:expected_value) { 4 }

  it_behaves_like 'a correct instrumented metric value', {
    options: { event: 'pushes', prefix: 'source_code' },
    time_frame: 'all'
  }

  it 'raises an exception if event option is not present' do
    expect do
      described_class.new(options: { prefix: 'source_code' }, time_frame: 'all')
    end.to raise_error(ArgumentError, /'event' option is required/)
  end

  it 'raises an exception if prefix option is not present' do
    expect do
      described_class.new(options: { event: 'pushes' }, time_frame: 'all')
    end.to raise_error(ArgumentError, /'prefix' option is required/)
  end

  describe 'children classes' do
    let(:options) { { event: 'pushes', prefix: 'source_code' } }

    context 'availability not defined' do
      subject { Class.new(described_class).new(time_frame: nil, options: options) }

      it 'returns default availability' do
        expect(subject.available?).to eq(true)
      end
    end

    context 'availability defined' do
      subject do
        Class.new(described_class) do
          available? { false }
        end.new(time_frame: nil, options: options)
      end

      it 'returns defined availability' do
        expect(subject.available?).to eq(false)
      end
    end
  end

  context "with usage prefix disabled" do
    let(:expected_value) { 3 }

    before do
      3.times do
        Gitlab::UsageDataCounters::WebIdeCounter.increment_merge_requests_count
      end
    end

    it_behaves_like 'a correct instrumented metric value', {
      options: { event: 'merge_requests_count', prefix: 'web_ide', include_usage_prefix: false },
      time_frame: 'all'
    }
  end

  context "with prefix disabled" do
    let(:expected_value) { 3 }

    before do
      3.times do
        Gitlab::UsageDataCounters::SearchCounter.count(:all_searches)
      end
    end

    it_behaves_like 'a correct instrumented metric value', {
      options: { event: 'all_searches_count', prefix: nil, include_usage_prefix: false }, time_frame: 'all'
    }
  end
end
