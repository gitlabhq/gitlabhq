# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::DeletionScheduledBacklogSampler, :clean_gitlab_redis_shared_state,
  feature_category: :groups_and_projects do
  include ExclusiveLeaseHelpers

  let(:lease_key) { 'gitlab/metrics/samplers/deletion_scheduled_backlog_sampler' }
  let(:sampler) { described_class.new }
  let(:age_gauge) { instance_double(Prometheus::Client::Gauge) }
  let(:count_gauge) { instance_double(Prometheus::Client::Gauge) }

  subject(:sample) { sampler.sample }

  before do
    allow(Gitlab::Metrics).to receive(:gauge)
      .with(described_class::OLDEST_AGE_METRIC, anything)
      .and_return(age_gauge)
    allow(Gitlab::Metrics).to receive(:gauge)
      .with(described_class::OVERDUE_COUNT_METRIC, anything)
      .and_return(count_gauge)
    allow(age_gauge).to receive(:set)
    allow(count_gauge).to receive(:set)
  end

  it_behaves_like 'metrics sampler', 'DELETION_SCHEDULED_BACKLOG_SAMPLER'

  describe '#sample' do
    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(deletion_scheduled_backlog_metric: false)
      end

      it 'does not set any metric' do
        expect(age_gauge).not_to receive(:set)
        expect(count_gauge).not_to receive(:set)

        sample
      end
    end

    context 'when the feature flag is enabled' do
      context 'when the lease cannot be obtained' do
        before do
          stub_exclusive_lease_taken(lease_key)
        end

        it 'does not set any metric' do
          expect(age_gauge).not_to receive(:set)
          expect(count_gauge).not_to receive(:set)

          sample
        end
      end

      context 'when there is no backlog' do
        it 'reports zero for both metrics' do
          expect(age_gauge).to receive(:set).with({}, 0)
          expect(count_gauge).to receive(:set).with({}, 0)

          sample
        end
      end

      context 'when records are scheduled for deletion', :freeze_time do
        # Overdue is deletion_adjourned_period (30d) + OVERDUE_SLACK (2d) = 32 days.
        # Records are created inside the frozen-time example so their
        # deletion_scheduled_at shares the same clock as Time.current.
        before do
          stub_application_setting(deletion_adjourned_period: 30)
          create(:group, deletion_scheduled_at: 40.days.ago)
          create(:group, deletion_scheduled_at: 10.days.ago)
        end

        it 'reports the age of the oldest record and the overdue count' do
          expect(age_gauge).to receive(:set).with({}, 40.days.to_i)
          # Only the 40-day-old record is past deletion_adjourned_period +
          # OVERDUE_SLACK; the 10-day-old one is still inside its retention window.
          expect(count_gauge).to receive(:set).with({}, 1)

          sample
        end
      end
    end
  end
end
