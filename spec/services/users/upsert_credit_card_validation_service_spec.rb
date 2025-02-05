# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpsertCreditCardValidationService, feature_category: :user_profile do
  include CryptoHelpers

  let_it_be_with_reload(:user) { create(:user) }

  let(:user_id) { user.id }

  let(:network) { 'American Express' }
  let(:holder_name) {  'John Smith' }
  let(:last_digits) {  '1111' }
  let(:expiration_year) { Date.today.year + 10 }
  let(:expiration_month) { 1 }
  let(:expiration_date) { Date.new(expiration_year, expiration_month, -1) }
  let(:credit_card_validated_at) { Time.utc(2020, 1, 1) }
  let(:zuora_payment_method_xid) { 'abc123' }
  let(:stripe_setup_intent_xid) { 'seti_abc123' }
  let(:stripe_payment_method_xid) { 'pm_abc123' }
  let(:stripe_card_fingerprint) { 'card123' }

  let(:params) do
    {
      user_id: user_id,
      credit_card_validated_at: credit_card_validated_at,
      credit_card_expiration_year: expiration_year,
      credit_card_expiration_month: expiration_month,
      credit_card_holder_name: holder_name,
      credit_card_type: network,
      credit_card_mask_number: last_digits,
      zuora_payment_method_xid: zuora_payment_method_xid,
      stripe_setup_intent_xid: stripe_setup_intent_xid,
      stripe_payment_method_xid: stripe_payment_method_xid,
      stripe_card_fingerprint: stripe_card_fingerprint
    }
  end

  describe '#execute' do
    subject(:service) { described_class.new(params) }

    context 'successfully set credit card validation record for the user' do
      context 'when user does not have credit card validation record' do
        it 'creates the credit card validation and returns a success', :aggregate_failures do
          expect(user.credit_card_validated_at).to be nil

          service_result = service.execute

          expect(service_result.status).to eq(:success)
          expect(service_result.message).to eq(_('Credit card validation record saved'))

          user.reload

          expect(user.credit_card_validation).to have_attributes(
            credit_card_validated_at: credit_card_validated_at,
            network_hash: sha256(network.downcase),
            holder_name_hash: sha256(holder_name.downcase),
            last_digits_hash: sha256(last_digits),
            expiration_date_hash: sha256(expiration_date.to_s),
            zuora_payment_method_xid: 'abc123',
            stripe_setup_intent_xid: 'seti_abc123',
            stripe_payment_method_xid: 'pm_abc123',
            stripe_card_fingerprint: 'card123'
          )
        end
      end

      context 'when user has credit card validation record' do
        let(:previous_credit_card_validated_at) { Time.utc(1999, 2, 2) }

        before do
          create(:credit_card_validation, user: user, credit_card_validated_at: previous_credit_card_validated_at)
        end

        it 'updates the credit card validation record and returns a success', :aggregate_failures do
          expect(user.credit_card_validated_at).to eq(previous_credit_card_validated_at)

          service_result = service.execute

          expect(service_result.status).to eq(:success)
          expect(service_result.message).to eq(_('Credit card validation record saved'))

          user.reload

          expect(user.credit_card_validated_at).to eq(credit_card_validated_at)
        end
      end
    end

    shared_examples 'returns an error without tracking the exception' do
      it 'does not send an exception to Gitlab::ErrorTracking' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        service.execute
      end

      it 'returns an error', :aggregate_failures do
        service_result = service.execute

        expect(service_result.status).to eq(:error)
        expect(service_result.message).to eq(_('Error saving credit card validation record'))
      end
    end

    context 'when the zuora_payment_method_xid is missing' do
      let(:zuora_payment_method_xid) { nil }

      it 'successfully validates the credit card' do
        # verify existing nil payment xid doesn't interfere with new ones for backwards compatibility
        create(:credit_card_validation, zuora_payment_method_xid: nil)

        service_result = service.execute

        expect(service_result).to be_success
        expect(service_result.message).to eq(_('Credit card validation record saved'))

        user.reload

        expect(user.credit_card_validated_at).to be_present
        expect(user.credit_card_validation).to have_attributes(zuora_payment_method_xid: nil)
      end
    end

    context 'when the stripe identifiers are missing' do
      let(:stripe_setup_intent_xid) { nil }
      let(:stripe_payment_method_xid) { nil }
      let(:stripe_card_fingerprint) { nil }

      it 'successfully validates the credit card' do
        service_result = service.execute

        expect(service_result).to be_success
        expect(service_result.message).to eq(_('Credit card validation record saved'))

        user.reload

        expect(user.credit_card_validated_at).to be_present
        expect(user.credit_card_validation).to have_attributes(
          stripe_setup_intent_xid: nil,
          stripe_payment_method_xid: nil,
          stripe_card_fingerprint: nil
        )
      end
    end

    context 'when the user_id does not exist' do
      let(:user_id) { non_existing_record_id }

      it_behaves_like 'returns an error without tracking the exception'
    end

    context 'when the request is missing the credit_card_validated_at field' do
      let(:credit_card_validated_at) { nil }

      it_behaves_like 'returns an error without tracking the exception'
    end

    context 'when the request is missing the user_id field' do
      let(:user_id) { nil }

      it_behaves_like 'returns an error without tracking the exception'
    end

    context 'when the validation params are invalid' do
      let(:last_digits) { '11111111111111111111111111111111111111111111111111' } # more than the 44 char limit

      it_behaves_like 'returns an error without tracking the exception'
    end

    context 'when a user has already been validated with this Zuora payment method' do
      before do
        create(:credit_card_validation, zuora_payment_method_xid: zuora_payment_method_xid)
      end

      it_behaves_like 'returns an error without tracking the exception'
    end

    context 'when there is an unexpected error' do
      let(:exception) { StandardError.new }

      before do
        allow_next_instance_of(::Users::CreditCardValidation) do |instance|
          allow(instance).to receive(:save!).and_raise(exception)
        end
      end

      it 'sends an exception to Gitlab::ErrorTracking' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception)

        service.execute
      end

      it 'returns an error', :aggregate_failures do
        service_result = service.execute

        expect(service_result.status).to eq(:error)
        expect(service_result.message).to eq(_('Error saving credit card validation record'))
      end
    end

    context 'when the credit card verification limit has been reached' do
      before do
        allow_next_instance_of(Users::CreditCardValidation) do |instance|
          allow(instance).to receive(:exceeded_daily_verification_limit?).and_return(true)
        end
      end

      it 'returns an error', :aggregate_failures do
        service_result = service.execute

        expect(service_result).to be_error
        expect(service_result.message).to eq('Credit card verification limit exceeded')
        expect(service_result.reason).to eq(:rate_limited)
      end
    end
  end
end
