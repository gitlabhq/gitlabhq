# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::UsageTrends::Measurement, type: :model do
  describe 'validation' do
    let!(:measurement) { create(:usage_trends_measurement) }

    it { is_expected.to validate_presence_of(:recorded_at) }
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_presence_of(:count) }
    it { is_expected.to validate_uniqueness_of(:recorded_at).scoped_to(:identifier) }
  end

  describe 'identifiers enum' do
    it 'maps to the correct values' do
      identifiers = {
        projects: 1,
        users: 2,
        issues: 3,
        merge_requests: 4,
        groups: 5,
        pipelines: 6,
        pipelines_succeeded: 7,
        pipelines_failed: 8,
        pipelines_canceled: 9,
        pipelines_skipped: 10,
        billable_users: 11
      }

      expect(described_class.identifiers).to eq(identifiers.with_indifferent_access)
    end
  end

  describe 'scopes' do
    let_it_be(:measurement_1) { create(:usage_trends_measurement, :project_count, recorded_at: 10.days.ago) }
    let_it_be(:measurement_2) { create(:usage_trends_measurement, :project_count, recorded_at: 2.days.ago) }
    let_it_be(:measurement_3) { create(:usage_trends_measurement, :group_count, recorded_at: 5.days.ago) }

    describe '.order_by_latest' do
      subject { described_class.order_by_latest }

      it { is_expected.to eq([measurement_2, measurement_3, measurement_1]) }
    end

    describe '.with_identifier' do
      subject { described_class.with_identifier(:projects) }

      it { is_expected.to match_array([measurement_1, measurement_2]) }
    end

    describe '.recorded_after' do
      subject { described_class.recorded_after(8.days.ago) }

      it { is_expected.to match_array([measurement_2, measurement_3]) }

      context 'when nil is given' do
        subject { described_class.recorded_after(nil) }

        it 'does not apply filtering' do
          expect(subject).to match_array([measurement_1, measurement_2, measurement_3])
        end
      end
    end

    describe '.recorded_before' do
      subject { described_class.recorded_before(4.days.ago) }

      it { is_expected.to match_array([measurement_1, measurement_3]) }

      context 'when nil is given' do
        subject { described_class.recorded_after(nil) }

        it 'does not apply filtering' do
          expect(subject).to match_array([measurement_1, measurement_2, measurement_3])
        end
      end
    end
  end

  describe '.identifier_query_mapping' do
    subject { described_class.identifier_query_mapping }

    it { is_expected.to be_a Hash }
  end

  describe '.identifier_min_max_queries' do
    subject { described_class.identifier_min_max_queries }

    it { is_expected.to be_a Hash }
  end

  describe '.measurement_identifier_values' do
    let(:expected_count) { described_class.identifiers.size }

    subject { described_class.measurement_identifier_values.count }

    it { is_expected.to eq(expected_count) }
  end

  describe '.find_latest_or_fallback' do
    subject(:count) { described_class.find_latest_or_fallback(:pipelines_skipped).count }

    context 'with usage statistics' do
      let!(:measurement) { create(:usage_trends_measurement, :pipelines_skipped_count) }

      it 'returns the latest stored measurement' do
        expect(count).to eq measurement.count
      end
    end

    context 'without usage statistics' do
      it 'returns the realtime query of the measurement' do
        expect(count).to eq 0
      end
    end
  end
end
