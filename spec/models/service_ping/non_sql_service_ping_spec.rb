# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::NonSqlServicePing, feature_category: :service_ping do
  before_all do
    create(:organization, :default)
  end

  describe 'scopes' do
    describe '.for_current_reporting_cycle' do
      subject(:recent_service_ping_reports) { described_class.for_current_reporting_cycle }

      before_all do
        create(:non_sql_service_ping, created_at: (described_class::REPORTING_CADENCE + 1.day).ago)
      end

      it 'returns nil where no records match filter criteria' do
        expect(recent_service_ping_reports).to be_empty
      end

      context 'with records matching filtering criteria' do
        let_it_be(:fresh_record) { create(:non_sql_service_ping) }
        let_it_be(:record_at_edge_of_time_range) do
          create(:non_sql_service_ping, created_at: described_class::REPORTING_CADENCE.ago)
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

    describe 'uniqueness validation' do
      let!(:existing_record) { create(:non_sql_service_ping) }

      it { is_expected.to validate_uniqueness_of(:recorded_at) }
    end
  end
end
