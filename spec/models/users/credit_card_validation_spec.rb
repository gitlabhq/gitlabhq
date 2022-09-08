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
end
