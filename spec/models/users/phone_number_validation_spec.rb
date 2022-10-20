# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::PhoneNumberValidation do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:banned_user) }

  it { is_expected.to validate_presence_of(:country) }
  it { is_expected.to validate_length_of(:country).is_at_most(3) }

  it { is_expected.to validate_presence_of(:international_dial_code) }

  it {
    is_expected.to validate_numericality_of(:international_dial_code)
      .only_integer
      .is_greater_than_or_equal_to(1)
      .is_less_than_or_equal_to(999)
  }

  it { is_expected.to validate_presence_of(:phone_number) }
  it { is_expected.to validate_length_of(:phone_number).is_at_most(12) }
  it { is_expected.to allow_value('555555').for(:phone_number) }
  it { is_expected.not_to allow_value('555-555').for(:phone_number) }
  it { is_expected.not_to allow_value('+555555').for(:phone_number) }
  it { is_expected.not_to allow_value('555 555').for(:phone_number) }

  it { is_expected.to validate_length_of(:telesign_reference_xid).is_at_most(255) }

  describe '.related_to_banned_user?' do
    let_it_be(:international_dial_code) { 1 }
    let_it_be(:phone_number) { '555' }

    let_it_be(:user) { create(:user) }
    let_it_be(:banned_user) { create(:user, :banned) }

    subject(:related_to_banned_user?) do
      described_class.related_to_banned_user?(international_dial_code, phone_number)
    end

    context 'when banned user has the same international dial code and phone number' do
      before do
        create(:phone_number_validation, user: banned_user)
      end

      it { is_expected.to eq(true) }
    end

    context 'when banned user has the same international dial code and phone number, but different country code' do
      before do
        create(:phone_number_validation, user: banned_user, country: 'CA')
      end

      it { is_expected.to eq(true) }
    end

    context 'when banned user does not have the same international dial code' do
      before do
        create(:phone_number_validation, user: banned_user, international_dial_code: 61)
      end

      it { is_expected.to eq(false) }
    end

    context 'when banned user does not have the same phone number' do
      before do
        create(:phone_number_validation, user: banned_user, phone_number: '666')
      end

      it { is_expected.to eq(false) }
    end

    context 'when not-banned user has the same international dial code and phone number' do
      before do
        create(:phone_number_validation, user: user)
      end

      it { is_expected.to eq(false) }
    end
  end
end
