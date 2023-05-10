# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreditCardValidation do
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_length_of(:holder_name).is_at_most(50) }
  it { is_expected.to validate_length_of(:network).is_at_most(32) }
  it { is_expected.to validate_numericality_of(:last_digits).is_less_than_or_equal_to(9999) }

  describe '.similar_records' do
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
end
