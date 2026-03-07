# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Metrics::ThreadNameCardinalityLimiter, feature_category: :scalability do
  describe '#normalize_thread_name' do
    where(:thread_names, :expected_name) do
      [
        [[nil], 'unnamed'],
        [['puma srv tp 1', 'puma srv tp 001', 'puma srv tp 002'], 'puma srv tp'],
        [%w[sidekiq_worker_thread], 'sidekiq_worker_thread'],
        [%w[some_sampler], 'some_sampler'],
        [%w[some_exporter], 'some_exporter'],
        [%w[ActionCable-worker-1 ActionCable-worker-7], 'ActionCable-worker'],
        [%w[worker-1 worker-2], 'worker'],
        [%w[unknown thing], 'unrecognized']
      ]
    end

    with_them do
      it 'normalizes the thread name' do
        thread_names.each do |thread_name|
          expect(described_class.normalize_thread_name(thread_name)).to eq(expected_name)
        end
      end
    end
  end
end
