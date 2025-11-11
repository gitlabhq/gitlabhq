# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ReassignPlaceholderThrottling, feature_category: :importers do
  let_it_be(:import_source_user) do
    create(:import_source_user, :with_reassigned_by_user)
  end

  subject(:throttling) { described_class.new(import_source_user) }

  describe '#db_health_check!' do
    before do
      allow(Rails.cache).to receive(:fetch).and_yield
    end

    context 'when the database is healthy' do
      it 'returns nil' do
        expect(Gitlab::Database::HealthStatus).to receive(:evaluate).and_call_original

        expect(throttling.db_health_check!).to be_nil
      end
    end

    context 'when reassignment_throttling feature flag is disabled' do
      before do
        stub_feature_flags(reassignment_throttling: false)
      end

      it 'returns nil' do
        expect(Gitlab::Database::HealthStatus).not_to receive(:evaluate)

        expect(throttling.db_health_check!).to be_nil
      end
    end

    context 'when the database is unhealthy' do
      let(:stop) { true }

      it 'raises an error' do
        stop_signal = instance_double(Gitlab::Database::HealthStatus::Signals::Stop, stop?: true)
        allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([stop_signal])

        expect { throttling.db_health_check! }.to raise_error(described_class::DatabaseHealthError)
      end
    end

    context 'when caching health status' do
      after do
        travel_back
      end

      it 'caches the result for 30 seconds' do
        expect(Rails.cache).to receive(:fetch).with(
          "reassign_placeholder_user_records_service_db_check",
          { expires_in: 30.seconds }
        ).thrice.and_yield

        throttling.db_health_check!

        travel 25.seconds
        throttling.db_health_check!

        travel 6.seconds

        throttling.db_health_check!
      end
    end
  end

  describe '#db_table_unavailable?' do
    context 'when a table is unavailable' do
      it 'returns true' do
        stop_signal = instance_double(Gitlab::Database::HealthStatus::Signals::Stop, stop?: true)
        allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([stop_signal])

        expect(throttling.db_table_unavailable?(User)).to be(true)
      end
    end

    context 'when the table is available' do
      it 'returns false' do
        expect(throttling.db_table_unavailable?(User)).to be(false)
      end
    end

    context 'when reassignment_throttling and reassignment_throttling_table_check feature flags are enabled' do
      it 'checks the table health status' do
        expect(throttling).to receive(:autovacuum_active?).and_return(false)

        expect(throttling.db_table_unavailable?(User)).to be(false)
      end
    end

    context 'when reassignment_throttling feature flag is disabled' do
      before do
        stub_feature_flags(reassignment_throttling: false)
      end

      it 'does not verify table status and returns false' do
        expect(throttling).not_to receive(:autovacuum_active?)

        expect(throttling.db_table_unavailable?(User)).to be(false)
      end
    end

    context 'when reassignment_throttling_table_check feature flag is disabled' do
      before do
        stub_feature_flags(reassignment_throttling_table_check: false)
      end

      it 'does not verify table status and returns false' do
        expect(throttling).not_to receive(:autovacuum_active?)

        expect(throttling.db_table_unavailable?(User)).to be(false)
      end
    end
  end
end
