# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::InProductMarketingEmail, type: :model do
  let(:track) { :create }
  let(:series) { 0 }

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

  describe '.for_user_with_track_and_series' do
    let_it_be(:user) { create(:user) }
    let_it_be(:in_product_marketing_email) { create(:in_product_marketing_email, series: 0, track: 0, user: user) }

    subject(:for_user_with_track_and_series) { described_class.for_user_with_track_and_series(user, track, series).first }

    context 'when record for user with given track and series exists' do
      it { is_expected.to eq(in_product_marketing_email) }
    end

    context 'when user is different' do
      let(:user) { build_stubbed(:user) }

      it { is_expected.to be_nil }
    end

    context 'when track is different' do
      let(:track) { 1 }

      it { is_expected.to be_nil }
    end

    context 'when series is different' do
      let(:series) { 1 }

      it { is_expected.to be_nil }
    end
  end

  describe '.save_cta_click' do
    let(:user) { create(:user) }

    subject(:save_cta_click) { described_class.save_cta_click(user, track, series) }

    context 'when there is no record' do
      it 'does not error' do
        expect { save_cta_click }.not_to raise_error
      end
    end

    context 'when there is no record for the track and series' do
      it 'does not perform an update' do
        other_email = create(:in_product_marketing_email, user: user, track: :verify, series: 2, cta_clicked_at: nil)

        expect { save_cta_click }.not_to change { other_email.reload }
      end
    end

    context 'when there is a record for the track and series' do
      it 'saves the cta click date' do
        email = create(:in_product_marketing_email, user: user, track: track, series: series, cta_clicked_at: nil)

        freeze_time do
          expect { save_cta_click }.to change { email.reload.cta_clicked_at }.from(nil).to(Time.zone.now)
        end
      end

      context 'cta_clicked_at is already set' do
        it 'does not update' do
          create(:in_product_marketing_email, user: user, track: track, series: series, cta_clicked_at: Time.zone.now)

          expect_next_found_instance_of(described_class) do |record|
            expect(record).not_to receive(:update)
          end

          save_cta_click
        end
      end
    end
  end
end
