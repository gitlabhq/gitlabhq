# frozen_string_literal: true

require 'spec_helper'

describe Reenqueuer do
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

  it_behaves_like 'it is rate limited to 1 call per', 5.seconds do
    let(:rate_limited_method) { subject.perform }
  end

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
    end

    context 'when #perform returns falsey' do
      it 'does not reenqueue the worker' do
        expect(worker_class).not_to receive(:perform_async)

        job.perform
      end
    end
  end
end

describe Reenqueuer::ReenqueuerSleeper do
  let_it_be(:dummy_class) do
    Class.new do
      include Reenqueuer::ReenqueuerSleeper

      def rate_limited_method
        ensure_minimum_duration(11.seconds) do
          # do work
        end
      end
    end
  end

  subject(:dummy) { dummy_class.new }

  # Test that rate_limited_method is rate limited by ensure_minimum_duration
  it_behaves_like 'it is rate limited to 1 call per', 11.seconds do
    let(:rate_limited_method) { dummy.rate_limited_method }
  end

  # Test ensure_minimum_duration more directly
  describe '#ensure_minimum_duration' do
    around do |example|
      # Allow Timecop.travel without the block form
      Timecop.safe_mode = false

      Timecop.freeze do
        example.run
      end

      Timecop.safe_mode = true
    end

    let(:minimum_duration) { 4.seconds }

    context 'when the block completes well before the minimum duration' do
      let(:time_left) { 3.seconds }

      it 'sleeps until the minimum duration' do
        expect(dummy).to receive(:sleep).with(a_value_within(0.01).of(time_left))

        dummy.ensure_minimum_duration(minimum_duration) do
          Timecop.travel(minimum_duration - time_left)
        end
      end
    end

    context 'when the block completes just before the minimum duration' do
      let(:time_left) { 0.1.seconds }

      it 'sleeps until the minimum duration' do
        expect(dummy).to receive(:sleep).with(a_value_within(0.01).of(time_left))

        dummy.ensure_minimum_duration(minimum_duration) do
          Timecop.travel(minimum_duration - time_left)
        end
      end
    end

    context 'when the block completes just after the minimum duration' do
      let(:time_over) { 0.1.seconds }

      it 'does not sleep' do
        expect(dummy).not_to receive(:sleep)

        dummy.ensure_minimum_duration(minimum_duration) do
          Timecop.travel(minimum_duration + time_over)
        end
      end
    end

    context 'when the block completes well after the minimum duration' do
      let(:time_over) { 10.seconds }

      it 'does not sleep' do
        expect(dummy).not_to receive(:sleep)

        dummy.ensure_minimum_duration(minimum_duration) do
          Timecop.travel(minimum_duration + time_over)
        end
      end
    end
  end
end
