# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RawUsageData do
  context 'scopes' do
    describe '.for_current_reporting_cycle' do
      subject(:recent_service_ping_reports) { described_class.for_current_reporting_cycle }

      before_all do
        create(:raw_usage_data, created_at: (described_class::REPORTING_CADENCE + 1.day).ago)
      end

      it 'returns nil where no records match filter criteria' do
        expect(recent_service_ping_reports).to be_empty
      end

      context 'with records matching filtering criteria' do
        let_it_be(:fresh_record) { create(:raw_usage_data) }
        let_it_be(:record_at_edge_of_time_range) do
          create(:raw_usage_data, created_at: described_class::REPORTING_CADENCE.ago)
        end

        it 'return records within reporting cycle time range ordered by creation time' do
          expect(recent_service_ping_reports).to eq [fresh_record, record_at_edge_of_time_range]
        end
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:payload) }
    it { is_expected.to validate_presence_of(:recorded_at) }

    context 'uniqueness validation' do
      let!(:existing_record) { create(:raw_usage_data) }

      it { is_expected.to validate_uniqueness_of(:recorded_at) }
    end

    describe '#update_version_metadata!' do
      let(:raw_usage_data) { create(:raw_usage_data) }

      it 'updates sent_at' do
        raw_usage_data.update_version_metadata!(usage_data_id: 123)

        expect(raw_usage_data.sent_at).not_to be_nil
      end

      it 'updates version_usage_data_id_value' do
        raw_usage_data.update_version_metadata!(usage_data_id: 123)

        expect(raw_usage_data.version_usage_data_id_value).not_to be_nil
      end
    end
  end
end
