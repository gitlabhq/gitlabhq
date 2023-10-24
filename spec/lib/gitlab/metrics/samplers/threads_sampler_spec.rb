# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::ThreadsSampler do
  subject { described_class.new }

  it_behaves_like 'metrics sampler', 'THREADS_SAMPLER'

  describe '#sample' do
    before do
      described_class::METRIC_DESCRIPTIONS.each_key do |metric|
        allow(subject.metrics[metric]).to receive(:set)
      end
    end

    it 'sets the gauge for the concurrency total' do
      expect(Gitlab::Runtime).to receive(:max_threads).and_return(9000)
      expect(subject.metrics[:max_expected_threads]).to receive(:set).with({}, 9000)

      subject.sample
    end

    context 'thread counts' do
      it 'reports if any of the threads per group uses the db' do
        threads = [
          fake_thread(described_class::SIDEKIQ_WORKER_THREAD_NAME, true), fake_thread(described_class::SIDEKIQ_WORKER_THREAD_NAME, false),
          fake_thread(described_class::SIDEKIQ_WORKER_THREAD_NAME, nil)
        ]
        allow(Thread).to receive(:list).and_return(threads)

        expect(subject.metrics[:running_threads]).to receive(:set)
          .with({ uses_db_connection: 'yes', thread_name: described_class::SIDEKIQ_WORKER_THREAD_NAME }, 1)
        expect(subject.metrics[:running_threads]).to receive(:set)
          .with({ uses_db_connection: 'no', thread_name: described_class::SIDEKIQ_WORKER_THREAD_NAME }, 2)

        subject.sample
      end

      context 'thread names', :aggregate_failures do
        where(:thread_names, :expected_names) do
          [
            [[nil], %w[unnamed]],
            [['puma threadpool 1', 'puma threadpool 001', 'puma threadpool 002'], ['puma threadpool']],
            [%w[sidekiq_worker_thread], %w[sidekiq_worker_thread]],
            [%w[some_sampler some_exporter], %w[some_sampler some_exporter]],
            [%w[unknown thing], %w[unrecognized]]
          ]
        end

        with_them do
          it do
            allow(Thread).to receive(:list).and_return(thread_names.map { |name| fake_thread(name) })

            expected_names.each do |expected_name|
              expect(subject.metrics[:running_threads]).to receive(:set)
                                                             .with({ uses_db_connection: 'yes', thread_name: expected_name }, instance_of(Integer))
              expect(subject.metrics[:running_threads]).to receive(:set)
                                                             .with({ uses_db_connection: 'no', thread_name: expected_name }, instance_of(Integer))
            end

            subject.sample
          end
        end
      end
    end

    def fake_thread(name = nil, db_connection = nil)
      thready = { uses_db_connection: db_connection }
      allow(thready).to receive(:name).and_return(name)

      thready
    end
  end
end
