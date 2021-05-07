# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpsertCreditCardValidationService do
  let_it_be(:user) { create(:user) }

  let(:user_id) { user.id }
  let(:credit_card_validated_time) { Time.utc(2020, 1, 1) }
  let(:params) { { user_id: user_id, credit_card_validated_at: credit_card_validated_time } }

  describe '#execute' do
    subject(:service) { described_class.new(params) }

    context 'successfully set credit card validation record for the user' do
      context 'when user does not have credit card validation record' do
        it 'creates the credit card validation and returns a success' do
          expect(user.credit_card_validated_at).to be nil

          result = service.execute

          expect(result.status).to eq(:success)
          expect(user.reload.credit_card_validated_at).to eq(credit_card_validated_time)
        end
      end

      context 'when user has credit card validation record' do
        let(:old_time) { Time.utc(1999, 2, 2) }

        before do
          create(:credit_card_validation, user: user, credit_card_validated_at: old_time)
        end

        it 'updates the credit card validation and returns a success' do
          expect(user.credit_card_validated_at).to eq(old_time)

          result = service.execute

          expect(result.status).to eq(:success)
          expect(user.reload.credit_card_validated_at).to eq(credit_card_validated_time)
        end
      end
    end

    shared_examples 'returns an error without tracking the exception' do
      it do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        result = service.execute

        expect(result.status).to eq(:error)
      end
    end

    context 'when user id does not exist' do
      let(:user_id) { non_existing_record_id }

      it_behaves_like 'returns an error without tracking the exception'
    end

    context 'when missing credit_card_validated_at' do
      let(:params) { { user_id: user_id } }

      it_behaves_like 'returns an error without tracking the exception'
    end

    context 'when missing user id' do
      let(:params) { { credit_card_validated_at: credit_card_validated_time } }

      it_behaves_like 'returns an error without tracking the exception'
    end

    context 'when unexpected exception happen' do
      it 'tracks the exception and returns an error' do
        expect(::Users::CreditCardValidation).to receive(:upsert).and_raise(e = StandardError.new('My exception!'))
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(e, class: described_class.to_s, params: params)

        result = service.execute

        expect(result.status).to eq(:error)
      end
    end
  end
end
