# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ZentaoTrackerData, feature_category: :integrations do
  it_behaves_like Integrations::BaseDataFields

  describe 'factory available' do
    let(:zentao_tracker_data) { create(:zentao_tracker_data) }

    it { expect(zentao_tracker_data.valid?).to eq true }
  end

  describe 'encrypted attributes' do
    subject { described_class.attr_encrypted_encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:url, :api_url, :zentao_product_xid, :api_token) }
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:url).is_at_most(2048) }
    it { is_expected.to validate_length_of(:api_url).is_at_most(2048) }
    it { is_expected.to validate_length_of(:zentao_product_xid).is_at_most(255) }
    it { is_expected.to validate_length_of(:api_token).is_at_most(255) }

    it 'does not invalidate existing records' do
      zentao_tracker_data = create(:zentao_tracker_data)

      zentao_tracker_data.assign_attributes(
        url: 'A' * 3000,
        api_url: 'B' * 3000,
        zentao_product_xid: 'C' * 260,
        api_token: 'D' * 260
      )

      zentao_tracker_data.save!(validate: false)

      expect(zentao_tracker_data.reload).to be_valid
    end
  end
end
