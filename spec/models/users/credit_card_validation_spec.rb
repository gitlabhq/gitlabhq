# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreditCardValidation do
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_length_of(:holder_name).is_at_most(26) }
  it { is_expected.to validate_length_of(:network).is_at_most(32) }
  it { is_expected.to validate_numericality_of(:last_digits).is_less_than_or_equal_to(9999) }

  describe '.similar_records' do
    let(:card_details) { subject.attributes.slice(:expiration_date, :last_digits, :holder_name) }

    subject(:credit_card_validation) { create(:credit_card_validation) }

    let!(:match1) { create(:credit_card_validation, card_details) }
    let!(:other1) { create(:credit_card_validation, card_details.merge(last_digits: 9)) }
    let!(:match2) { create(:credit_card_validation, card_details) }
    let!(:other2) { create(:credit_card_validation, card_details.merge(holder_name: 'foo bar')) }

    it 'returns records with matching credit card, ordered by credit_card_validated_at' do
      expect(subject.similar_records).to eq([match2, match1, subject])
    end
  end
end
