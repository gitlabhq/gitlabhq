# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::AggregationSchedule, :clean_gitlab_redis_shared_state, type: :model do
  include ExclusiveLeaseHelpers

  it { is_expected.to belong_to :namespace }

  describe '.delay_timeout' do
    context 'when timeout is set on redis' do
      it 'uses personalized timeout' do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class::REDIS_SHARED_KEY, 1.hour)
        end

        expect(described_class.delay_timeout).to eq(1.hour)
      end
    end

    context 'when timeout is not set on redis' do
      it 'uses default timeout' do
        expect(described_class.delay_timeout).to eq(3.hours)
      end
    end
  end

  describe '#schedule_root_storage_statistics' do
    let(:namespace) { create(:namespace) }
    let(:aggregation_schedule) { namespace.build_aggregation_schedule }
    let(:lease_key) { "namespace:namespaces_root_statistics:#{namespace.id}" }

    context "when we can't obtain the lease" do
      it 'does not schedule the workers' do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

        expect(Namespaces::RootStatisticsWorker)
          .not_to receive(:perform_async)

        expect(Namespaces::RootStatisticsWorker)
          .not_to receive(:perform_in)

        aggregation_schedule.save!
      end
    end

    context 'when we can obtain the lease' do
      it 'schedules a root storage statistics after create' do
        stub_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_async).once

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in).once
          .with(described_class::DEFAULT_LEASE_TIMEOUT, aggregation_schedule.namespace_id)

        aggregation_schedule.save!
      end

      it 'does not release the lease' do
        stub_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

        aggregation_schedule.save!

        exclusive_lease = aggregation_schedule.exclusive_lease
        expect(exclusive_lease.exists?).to be_truthy
      end

      it 'only executes the workers once' do
        # Avoid automatic deletion of Namespace::AggregationSchedule
        # for testing purposes.
        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_async).once
          .and_return(nil)

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in).once
          .with(described_class::DEFAULT_LEASE_TIMEOUT, aggregation_schedule.namespace_id)
          .and_return(nil)

        # Scheduling workers for the first time
        aggregation_schedule.schedule_root_storage_statistics

        # Executing again, this time workers should not be scheduled
        # due to the lease not been released.
        aggregation_schedule.schedule_root_storage_statistics
      end
    end

    context 'with a personalized lease timeout' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class::REDIS_SHARED_KEY, 1.hour)
        end
      end

      it 'uses a personalized time' do
        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in)
          .with(1.hour, aggregation_schedule.namespace_id)

        aggregation_schedule.save!
      end
    end
  end
end
