# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RawUsageData do
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
