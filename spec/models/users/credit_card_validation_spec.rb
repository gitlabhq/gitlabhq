# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreditCardValidation, feature_category: :user_profile do
  include CryptoHelpers

  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_length_of(:holder_name).is_at_most(50) }
  it { is_expected.to validate_length_of(:network).is_at_most(32) }
  it { is_expected.to validate_numericality_of(:last_digits).is_less_than_or_equal_to(9999) }

  it { is_expected.to validate_length_of(:last_digits_hash).is_at_most(44) }
  it { is_expected.to validate_length_of(:holder_name_hash).is_at_most(44) }
  it { is_expected.to validate_length_of(:expiration_date_hash).is_at_most(44) }
  it { is_expected.to validate_length_of(:network_hash).is_at_most(44) }

  it { is_expected.to validate_length_of(:zuora_payment_method_xid).is_at_most(50) }

  context 'when there is an existing record with this zuora_payment_method_xid' do
    subject { build(:credit_card_validation, zuora_payment_method_xid: 'abc123') }

    it { is_expected.to validate_uniqueness_of(:zuora_payment_method_xid).allow_nil }
  end

  describe '#similar_records' do
    let_it_be(:credit_card_validation) { create(:credit_card_validation) }

    let_it_be(:card_details) do
      credit_card_validation.attributes.with_indifferent_access.slice(
        :expiration_date, :last_digits, :network, :holder_name
      )
    end

    let_it_be(:match_1) { create(:credit_card_validation, card_details) }
    let_it_be(:match_2) { create(:credit_card_validation, card_details.merge(holder_name: 'Bob')) }

    let_it_be(:non_match_1) { create(:credit_card_validation, card_details.merge(last_digits: 9999)) }
    let_it_be(:non_match_2) { create(:credit_card_validation, card_details.merge(network: 'Mastercard')) }
    let_it_be(:non_match_3) do
      create(:credit_card_validation, card_details.merge(expiration_date: 2.years.from_now.to_date))
    end

    it 'returns matches with the same last_digits, expiration and network, ordered by credit_card_validated_at' do
      # eq is used instead of match_array because rows are sorted by credit_card_validated_at in desc order
      expect(credit_card_validation.similar_records).to eq([match_2, match_1, credit_card_validation])
    end
  end

  describe '#similar_holder_names_count' do
    context 'when holder_name is present' do
      let_it_be(:credit_card_validation) { create(:credit_card_validation, holder_name: 'ALICE M SMITH') }

      let_it_be(:match) { create(:credit_card_validation, holder_name: 'Alice M Smith') }
      let_it_be(:non_match) { create(:credit_card_validation, holder_name: 'Bob B Brown') }

      it 'returns the count of cards with similar case insensitive holder names' do
        expect(credit_card_validation.similar_holder_names_count).to eq(2)
      end
    end

    context 'when holder_name is nil' do
      let_it_be(:credit_card_validation) { create(:credit_card_validation, holder_name: nil) }

      it 'returns 0' do
        expect(subject.similar_holder_names_count).to eq(0)
      end
    end
  end

  describe 'scopes' do
    describe '.find_or_initialize_by_user' do
      subject(:find_or_initialize_by_user) { described_class.find_or_initialize_by_user(user.id) }

      let_it_be(:user) { create(:user) }

      context 'with no existing credit card record' do
        it { is_expected.to be_a_new_record }
      end

      context 'with existing credit card record' do
        let_it_be(:credit_card_validation) { create(:credit_card_validation, user: user) }

        it { is_expected.to eq(credit_card_validation) }
      end
    end

    describe '.by_banned_user' do
      subject(:by_banned_user) { described_class.by_banned_user }

      let_it_be(:banned_user) { create(:banned_user) }
      let_it_be(:credit_card) { create(:credit_card_validation) }
      let_it_be(:banned_user_credit_card) { create(:credit_card_validation, user: banned_user.user) }

      it 'returns only records associated to banned users' do
        expect(by_banned_user).to match_array([banned_user_credit_card])
      end
    end

    describe '.similar_by_holder_name' do
      subject(:similar_by_holder_name) { described_class.similar_by_holder_name(holder_name_hash) }

      let_it_be(:credit_card_validation) { create(:credit_card_validation, holder_name: 'Alice M Smith') }
      let_it_be(:match) { create(:credit_card_validation, holder_name: 'ALICE M SMITH') }

      context 'when holder_name_hash is present' do
        let_it_be(:holder_name_hash) { credit_card_validation.holder_name_hash }

        it 'returns records with similar holder names case-insensitively' do
          expect(similar_by_holder_name).to match_array([credit_card_validation, match])
        end
      end

      context 'when holder_name_hash is nil' do
        let_it_be(:holder_name_hash) { nil }

        it 'returns an empty array' do
          expect(similar_by_holder_name).to be_empty
        end
      end
    end

    describe '.similar_to' do
      subject(:similar_to) { described_class.similar_to(credit_card_validation) }

      let_it_be(:credit_card_validation) { create(:credit_card_validation) }

      let_it_be(:match) do
        create(:credit_card_validation,
          expiration_date: credit_card_validation.expiration_date,
          last_digits: credit_card_validation.last_digits,
          network: credit_card_validation.network
        )
      end

      let_it_be(:non_match) do
        create(:credit_card_validation,
          expiration_date: credit_card_validation.expiration_date,
          last_digits: credit_card_validation.last_digits,
          network: 'Mastercard'
        )
      end

      it 'returns only records with similar expiration_date, last_digits, and network attribute values' do
        expect(similar_to).to match_array([credit_card_validation, match])
      end
    end
  end

  describe '#used_by_banned_user?' do
    subject(:used_by_banned_user) { credit_card_validation.used_by_banned_user? }

    let_it_be(:credit_card_validation) { create(:credit_card_validation) }

    let_it_be(:card_details) do
      credit_card_validation.attributes.with_indifferent_access.slice(
        :expiration_date, :last_digits, :network, :holder_name
      )
    end

    let_it_be(:banned_user) { create(:banned_user) }

    context 'when there is a similar credit card associated to a banned user' do
      context 'when holder names match exactly' do
        before do
          create(:credit_card_validation, card_details.merge(user: banned_user.user))
        end

        it { is_expected.to be(true) }
      end

      context 'when holder names do not match exactly' do
        before do
          create(:credit_card_validation, card_details.merge(user: banned_user.user, holder_name: 'John M Smith'))
        end

        it { is_expected.to be(false) }
      end
    end

    context 'when there are no similar credit cards associated to a banned user' do
      before do
        create(:credit_card_validation,
          user: banned_user.user,
          network: 'Mastercard',
          last_digits: 1111,
          holder_name: 'Jane Smith'
        )
      end

      it { is_expected.to be(false) }
    end

    context 'when there is a similar credit card but it is not associated to a banned user' do
      before do
        create(:credit_card_validation, card_details)
      end

      it { is_expected.to be(false) }
    end
  end

  describe 'before_save' do
    describe '#set_last_digits_hash' do
      let(:credit_card_validation) { build(:credit_card_validation, last_digits: last_digits) }

      subject(:save_credit_card_validation) { credit_card_validation.save! }

      context 'when last_digits are nil' do
        let(:last_digits) { nil }

        it { expect { save_credit_card_validation }.not_to change { credit_card_validation.last_digits_hash } }
      end

      context 'when last_digits has a blank value' do
        let(:last_digits) { ' ' }

        it { expect(credit_card_validation).to be_invalid }
      end

      context 'when last_digits has a value' do
        let(:last_digits) { 1111 }
        let(:expected_last_digits_hash) { sha256(last_digits) }

        it 'assigns correct last_digits_hash value' do
          expect { save_credit_card_validation }.to change {
                                                      credit_card_validation.last_digits_hash
                                                    }.from(nil).to(expected_last_digits_hash)
        end
      end
    end

    describe '#set_holder_name_hash' do
      let(:credit_card_validation) { build(:credit_card_validation, holder_name: holder_name) }

      subject(:save_credit_card_validation) { credit_card_validation.save! }

      context 'when holder_name is nil' do
        let(:holder_name) { nil }

        it { expect { save_credit_card_validation }.not_to change { credit_card_validation.holder_name_hash } }
      end

      context 'when holder_name has a blank value' do
        let(:holder_name) { ' ' }

        it { expect { save_credit_card_validation }.not_to change { credit_card_validation.holder_name_hash } }
      end

      context 'when holder_name has a value' do
        let(:holder_name) { 'John Smith' }
        let(:expected_holder_name_hash) { sha256(holder_name.downcase) }

        it 'lowercases holder_name and assigns correct holder_name_hash value' do
          expect { save_credit_card_validation }.to change {
                                                      credit_card_validation.holder_name_hash
                                                    }.from(nil).to(expected_holder_name_hash)
        end
      end
    end

    describe '#set_network_hash' do
      let(:credit_card_validation) { build(:credit_card_validation, network: network) }

      subject(:save_credit_card_validation) { credit_card_validation.save! }

      context 'when network is nil' do
        let(:network) { nil }

        it { expect { save_credit_card_validation }.not_to change { credit_card_validation.network_hash } }
      end

      context 'when network has a blank value' do
        let(:network) { ' ' }

        it { expect { save_credit_card_validation }.not_to change { credit_card_validation.network_hash } }
      end

      context 'when network has a value' do
        let(:network) { 'Visa' }
        let(:expected_network_hash) { sha256(network.downcase) }

        it 'lowercases network and assigns correct network_hash value' do
          expect { save_credit_card_validation }.to change {
                                                      credit_card_validation.network_hash
                                                    }.from(nil).to(expected_network_hash)
        end
      end
    end

    describe '#set_expiration_date_hash' do
      let(:credit_card_validation) { build(:credit_card_validation, expiration_date: expiration_date) }

      subject(:save_credit_card_validation) { credit_card_validation.save! }

      context 'when expiration_date is nil' do
        let(:expiration_date) { nil }

        it { expect { save_credit_card_validation }.not_to change { credit_card_validation.expiration_date_hash } }
      end

      context 'when expiration_date has a blank value' do
        let(:expiration_date) { ' ' }

        it { expect { save_credit_card_validation }.not_to change { credit_card_validation.expiration_date_hash } }
      end

      context 'when expiration_date has a value' do
        let(:expiration_date) { 1.year.from_now.to_date }
        let(:expected_expiration_date_hash) { sha256(expiration_date.to_s) }

        it 'assigns correct expiration_date_hash value' do
          expect { save_credit_card_validation }.to change {
                                                      credit_card_validation.expiration_date_hash
                                                    }.from(nil).to(expected_expiration_date_hash)
        end
      end
    end

    describe '#exceeded_daily_verification_limit?' do
      let(:credit_card_validation) { build(:credit_card_validation) }

      subject(:exceeded_limit?) { credit_card_validation.exceeded_daily_verification_limit? }

      before do
        stub_const("#{described_class}::DAILY_VERIFICATION_LIMIT", 1)
      end

      it { is_expected.to eq(false) }

      context 'when the limit has been exceeded' do
        before do
          create(:credit_card_validation, stripe_card_fingerprint: credit_card_validation.stripe_card_fingerprint)
        end

        it { is_expected.to eq(true) }
      end

      context 'when the limit is exceeded but records have credit_card_validated_at > 24 hours' do
        before do
          create(
            :credit_card_validation,
            stripe_card_fingerprint: credit_card_validation.stripe_card_fingerprint,
            credit_card_validated_at: 25.hours.ago
          )
        end

        it { is_expected.to eq(false) }
      end
    end
  end
end
