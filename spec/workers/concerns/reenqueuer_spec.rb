# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Reenqueuer, feature_category: :shared do
  include ExclusiveLeaseHelpers

  let_it_be(:worker_class) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker
      prepend Reenqueuer

      attr_reader :performed_args

      def perform(*args)
        @performed_args = args

        success? # for stubbing
      end

      def success?
        false
      end

      def lease_timeout
        30.seconds
      end
    end
  end

  subject(:job) { worker_class.new }

  before do
    allow(job).to receive(:sleep) # faster tests
  end

  it_behaves_like 'reenqueuer'

  it_behaves_like '#perform is rate limited to 1 call per', 5.seconds

  it 'disables Sidekiq retries' do
    expect(job.sidekiq_options_hash).to include('retry' => false)
  end

  describe '#perform', :clean_gitlab_redis_shared_state do
    let(:arbitrary_args) { [:foo, 'bar', { a: 1 }] }

    context 'when the lease is available' do
      it 'does perform' do
        job.perform(*arbitrary_args)

        expect(job.performed_args).to eq(arbitrary_args)
      end
    end

    context 'when the lease is taken' do
      before do
        stub_exclusive_lease_taken(job.lease_key)
      end

      it 'does not perform' do
        job.perform(*arbitrary_args)

        expect(job.performed_args).to be_nil
      end
    end

    context 'when #perform returns truthy' do
      before do
        allow(job).to receive(:success?).and_return(true)
      end

      it 'reenqueues the worker' do
        expect(worker_class).to receive(:perform_async)

        job.perform
      end

      it 'returns the original value from #perform' do
        expect(job.perform).to eq(true)
      end
    end

    context 'when #perform returns falsey' do
      it 'does not reenqueue the worker' do
        expect(worker_class).not_to receive(:perform_async)

        job.perform
      end

      it 'returns the original value from #perform' do
        expect(job.perform).to eq(false)
      end
    end
  end
end

RSpec.describe Reenqueuer::ReenqueuerSleeper do
  let_it_be(:dummy_class) do
    Class.new do
      include Reenqueuer::ReenqueuerSleeper

      def perform
        ensure_minimum_duration(11.seconds) do
          # do work
        end
      end
    end
  end

  subject(:dummy) { dummy_class.new }

  # Slightly higher-level test of ensure_minimum_duration since we conveniently
  # already have this shared example anyway.
  it_behaves_like '#perform is rate limited to 1 call per', 11.seconds

  # Unit test ensure_minimum_duration
  describe '#ensure_minimum_duration' do
    around do |example|
      freeze_time { example.run }
    end

    let(:minimum_duration) { 4.seconds }

    context 'when the block completes well before the minimum duration' do
      let(:time_left) { 3.seconds }

      it 'sleeps until the minimum duration' do
        expect(dummy).to receive(:sleep).with(a_value_within(0.01).of(time_left))

        dummy.ensure_minimum_duration(minimum_duration) do
          travel(minimum_duration - time_left)
        end
      end
    end

    context 'when the block completes just before the minimum duration' do
      let(:time_left) { 1.second }

      it 'sleeps until the minimum duration' do
        expect(dummy).to receive(:sleep).with(a_value_within(0.01).of(time_left))

        dummy.ensure_minimum_duration(minimum_duration) do
          travel(minimum_duration - time_left)
        end
      end
    end

    context 'when the block completes just after the minimum duration' do
      let(:time_over) { 1.second }

      it 'does not sleep' do
        expect(dummy).not_to receive(:sleep)

        dummy.ensure_minimum_duration(minimum_duration) do
          travel(minimum_duration + time_over)
        end
      end
    end

    context 'when the block completes well after the minimum duration' do
      let(:time_over) { 10.seconds }

      it 'does not sleep' do
        expect(dummy).not_to receive(:sleep)

        dummy.ensure_minimum_duration(minimum_duration) do
          travel(minimum_duration + time_over)
        end
      end
    end
  end
end
