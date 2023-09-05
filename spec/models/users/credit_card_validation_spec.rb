# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreditCardValidation, feature_category: :user_profile do
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_length_of(:holder_name).is_at_most(50) }
  it { is_expected.to validate_length_of(:network).is_at_most(32) }
  it { is_expected.to validate_numericality_of(:last_digits).is_less_than_or_equal_to(9999) }

  it { is_expected.to validate_length_of(:last_digits_hash).is_at_most(44) }
  it { is_expected.to validate_length_of(:holder_name_hash).is_at_most(44) }
  it { is_expected.to validate_length_of(:expiration_date_hash).is_at_most(44) }
  it { is_expected.to validate_length_of(:network_hash).is_at_most(44) }

  describe '#similar_records' do
    let(:card_details) do
      subject.attributes.with_indifferent_access.slice(:expiration_date, :last_digits, :network, :holder_name)
    end

    subject!(:credit_card_validation) { create(:credit_card_validation, holder_name: 'Alice') }

    let!(:match1) { create(:credit_card_validation, card_details) }
    let!(:match2) { create(:credit_card_validation, card_details.merge(holder_name: 'Bob')) }
    let!(:non_match1) { create(:credit_card_validation, card_details.merge(last_digits: 9)) }
    let!(:non_match2) { create(:credit_card_validation, card_details.merge(network: 'unknown')) }
    let!(:non_match3) do
      create(:credit_card_validation, card_details.dup.tap { |h| h[:expiration_date] += 1.year })
    end

    it 'returns matches with the same last_digits, expiration and network, ordered by credit_card_validated_at' do
      expect(subject.similar_records).to eq([match2, match1, subject])
    end
  end

  describe '#similar_holder_names_count' do
    subject!(:credit_card_validation) { create(:credit_card_validation, holder_name: holder_name) }

    context 'when holder_name is present' do
      let(:holder_name) { 'ALICE M SMITH' }

      let!(:match) { create(:credit_card_validation, holder_name: 'Alice M Smith') }
      let!(:non_match) { create(:credit_card_validation, holder_name: 'Bob B Brown') }

      it 'returns the count of cards with similar case insensitive holder names' do
        expect(subject.similar_holder_names_count).to eq(2)
      end
    end

    context 'when holder_name is nil' do
      let(:holder_name) { nil }

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
      let(:banned_user) { create(:banned_user) }
      let!(:credit_card) { create(:credit_card_validation) }
      let!(:banned_user_credit_card) { create(:credit_card_validation, user: banned_user.user) }

      it 'returns only records associated to banned users' do
        expect(described_class.by_banned_user).to match_array([banned_user_credit_card])
      end
    end

    describe '.similar_by_holder_name' do
      let!(:credit_card) { create(:credit_card_validation, holder_name: 'CARD MCHODLER') }
      let!(:credit_card2) { create(:credit_card_validation, holder_name: 'RICHIE RICH') }

      it 'returns only records that case-insensitive match the given holder name' do
        expect(described_class.similar_by_holder_name('card mchodler')).to match_array([credit_card])
      end

      context 'when given holder name is falsey' do
        it 'returns [] when given holder name is ""' do
          expect(described_class.similar_by_holder_name('')).to match_array([])
        end

        it 'returns [] when given holder name is nil' do
          expect(described_class.similar_by_holder_name(nil)).to match_array([])
        end
      end
    end

    describe '.similar_to' do
      let(:credit_card) { create(:credit_card_validation) }

      let!(:credit_card2) do
        create(:credit_card_validation,
          expiration_date: credit_card.expiration_date,
          last_digits: credit_card.last_digits,
          network: credit_card.network
        )
      end

      let!(:credit_card3) do
        create(:credit_card_validation,
          expiration_date: credit_card.expiration_date,
          last_digits: credit_card.last_digits,
          network: 'UnknownCCNetwork'
        )
      end

      it 'returns only records with similar expiration_date, last_digits, and network attribute values' do
        expect(described_class.similar_to(credit_card)).to match_array([credit_card, credit_card2])
      end
    end
  end

  describe '#used_by_banned_user?' do
    let(:credit_card_details) do
      {
        holder_name: 'Christ McLovin',
        expiration_date: 2.years.from_now.end_of_month,
        last_digits: 4242,
        network: 'Visa'
      }
    end

    let!(:credit_card) { create(:credit_card_validation, credit_card_details) }

    subject { credit_card }

    context 'when there is a similar credit card associated to a banned user' do
      let_it_be(:banned_user) { create(:banned_user) }

      let(:attrs) { credit_card_details.merge({ user: banned_user.user }) }
      let!(:similar_credit_card) { create(:credit_card_validation, attrs) }

      it { is_expected.to be_used_by_banned_user }

      context 'when holder names do not match' do
        let!(:similar_credit_card) do
          create(:credit_card_validation, attrs.merge({ holder_name: 'Mary Goody' }))
        end

        it { is_expected.not_to be_used_by_banned_user }
      end

      context 'when .similar_to returns nothing' do
        let!(:similar_credit_card) do
          create(:credit_card_validation, attrs.merge({ network: 'DifferentNetwork' }))
        end

        it { is_expected.not_to be_used_by_banned_user }
      end
    end

    context 'when there is a similar credit card not associated to a banned user' do
      let!(:similar_credit_card) do
        create(:credit_card_validation, credit_card_details)
      end

      it { is_expected.not_to be_used_by_banned_user }
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

        it { expect { save_credit_card_validation }.not_to change { credit_card_validation.last_digits_hash } }
      end

      context 'when last_digits has a value' do
        let(:last_digits) { 1111 }
        let(:expected_last_digits_hash) { Gitlab::CryptoHelper.sha256(last_digits) }

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
        let(:expected_holder_name_hash) { Gitlab::CryptoHelper.sha256(holder_name.downcase) }

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
        let(:expected_network_hash) { Gitlab::CryptoHelper.sha256(network.downcase) }

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
        let(:expected_expiration_date_hash) { Gitlab::CryptoHelper.sha256(expiration_date.to_s) }

        it 'assigns correct expiration_date_hash value' do
          expect { save_credit_card_validation }.to change {
                                                      credit_card_validation.expiration_date_hash
                                                    }.from(nil).to(expected_expiration_date_hash)
        end
      end
    end
  end
end
