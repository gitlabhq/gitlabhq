# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::AggregationSchedule, :clean_gitlab_redis_shared_state, type: :model do
  include ExclusiveLeaseHelpers

  let(:namespace) { create(:namespace) }
  let(:aggregation_schedule) { namespace.build_aggregation_schedule }
  let(:default_timeout) { aggregation_schedule.default_lease_timeout }

  it { is_expected.to belong_to :namespace }

  describe "#default_lease_timeout" do
    before do
      aggregation_schedule.save!
    end

    it 'returns namespace_aggregation_schedule_lease_duration value from Gitlab CurrentSettings' do
      allow(::Gitlab::CurrentSettings).to receive(:namespace_aggregation_schedule_lease_duration_in_seconds)
        .and_return(240)

      expect(aggregation_schedule.default_lease_timeout).to eq 4.minutes.to_i
    end
  end

  describe '#schedule_root_storage_statistics' do
    let(:lease_key) { "namespace:namespaces_root_statistics:#{namespace.id}" }

    context "when we can't obtain the lease" do
      it 'does not schedule the workers' do
        stub_exclusive_lease_taken(lease_key, timeout: default_timeout)

        expect(Namespaces::RootStatisticsWorker)
          .not_to receive(:perform_async)

        expect(Namespaces::RootStatisticsWorker)
          .not_to receive(:perform_in)

        aggregation_schedule.save!
      end
    end

    context 'when we can obtain the lease' do
      it 'schedules a root storage statistics after create' do
        stub_exclusive_lease(lease_key, timeout: default_timeout)

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_async).once

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in).once
          .with(default_timeout, aggregation_schedule.namespace_id)

        aggregation_schedule.save!
      end

      it 'does not release the lease' do
        stub_exclusive_lease(lease_key, timeout: default_timeout)

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
          .with(default_timeout, aggregation_schedule.namespace_id)
          .and_return(nil)

        # Scheduling workers for the first time
        aggregation_schedule.schedule_root_storage_statistics

        # Executing again, this time workers should not be scheduled
        # due to the lease not been released.
        aggregation_schedule.schedule_root_storage_statistics
      end
    end
  end
end
