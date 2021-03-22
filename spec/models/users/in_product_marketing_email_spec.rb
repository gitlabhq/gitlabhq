# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::InProductMarketingEmail, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:in_product_marketing_email) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:track) }
    it { is_expected.to validate_presence_of(:series) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([:track, :series]).with_message('has already been sent') }
  end

  describe '.without_track_or_series' do
    let(:track) { 0 }
    let(:series) { 0 }

    let_it_be(:in_product_marketing_email) { create(:in_product_marketing_email, series: 0, track: 0) }

    subject(:without_track_or_series) { described_class.without_track_or_series(track, series) }

    context 'for the same track and series' do
      it { is_expected.to be_empty }
    end

    context 'for a different track' do
      let(:track) { 1 }

      it { is_expected.to eq([in_product_marketing_email])}
    end

    context 'for a different series' do
      let(:series) { 1 }

      it { is_expected.to eq([in_product_marketing_email])}
    end
  end
end
