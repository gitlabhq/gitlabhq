# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpsertCreditCardValidationService, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  let(:user_id) { user.id }
  let(:credit_card_validated_time) { Time.utc(2020, 1, 1) }
  let(:expiration_year) { Date.today.year + 10 }
  let(:params) do
    {
      user_id: user_id,
      credit_card_validated_at: credit_card_validated_time,
      credit_card_expiration_year: expiration_year,
      credit_card_expiration_month: 1,
      credit_card_holder_name: 'John Smith',
      credit_card_type: 'AmericanExpress',
      credit_card_mask_number: '1111'
    }
  end

  describe '#execute' do
    subject(:service) { described_class.new(params) }

    context 'successfully set credit card validation record for the user' do
      context 'when user does not have credit card validation record' do
        it 'creates the credit card validation and returns a success' do
          expect(user.credit_card_validated_at).to be nil

          result = service.execute

          expect(result.status).to eq(:success)

          user.reload

          expect(user.credit_card_validation).to have_attributes(
            credit_card_validated_at: credit_card_validated_time,
            network: 'AmericanExpress',
            holder_name: 'John Smith',
            last_digits: 1111,
            expiration_date: Date.new(expiration_year, 1, 31)
          )
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

    shared_examples 'returns an error, tracking the exception' do
      it do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

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

      it_behaves_like 'returns an error, tracking the exception'
    end

    context 'when missing user id' do
      let(:params) { { credit_card_validated_at: credit_card_validated_time } }

      it_behaves_like 'returns an error, tracking the exception'
    end

    context 'when unexpected exception happen' do
      it 'tracks the exception and returns an error' do
        logged_params = {
          credit_card_validated_at: credit_card_validated_time,
          expiration_date: Date.new(expiration_year, 1, 31),
          holder_name: "John Smith",
          last_digits: 1111,
          network: "AmericanExpress",
          user_id: user_id
        }

        expect(::Users::CreditCardValidation).to receive(:upsert).and_raise(e = StandardError.new('My exception!'))
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(e, class: described_class.to_s, params: logged_params)

        result = service.execute

        expect(result.status).to eq(:error)
      end
    end
  end
end
