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

  describe '.without_track_and_series' do
    let(:track) { :create }
    let(:series) { 0 }

    let_it_be(:user) { create(:user) }

    subject(:without_track_and_series) { User.merge(described_class.without_track_and_series(track, series)) }

    before do
      create(:in_product_marketing_email, track: :create, series: 0, user: user)
      create(:in_product_marketing_email, track: :create, series: 1, user: user)
      create(:in_product_marketing_email, track: :verify, series: 0, user: user)
    end

    context 'when given track and series already exists' do
      it { expect(without_track_and_series).to be_empty }
    end

    context 'when track does not exist' do
      let(:track) { :trial }

      it { expect(without_track_and_series).to eq [user] }
    end

    context 'when series does not exist' do
      let(:series) { 2 }

      it { expect(without_track_and_series).to eq [user] }
    end

    context 'when no track or series for a user exists' do
      let(:track) { :create }
      let(:series) { 0 }

      before do
        @other_user = create(:user)
      end

      it { expect(without_track_and_series).to eq [@other_user] }
    end
  end
end
