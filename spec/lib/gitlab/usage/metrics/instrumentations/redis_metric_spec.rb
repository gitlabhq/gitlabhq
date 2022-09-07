# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::RedisMetric, :clean_gitlab_redis_shared_state do
  before do
    4.times do
      Gitlab::UsageDataCounters::SourceCodeCounter.count(:pushes)
    end
  end

  let(:expected_value) { 4 }

  it_behaves_like 'a correct instrumented metric value', { options: { event: 'pushes', prefix: 'source_code' } }

  it 'raises an exception if event option is not present' do
    expect { described_class.new(prefix: 'source_code') }.to raise_error(ArgumentError)
  end

  it 'raises an exception if prefix option is not present' do
    expect { described_class.new(event: 'pushes') }.to raise_error(ArgumentError)
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
end
