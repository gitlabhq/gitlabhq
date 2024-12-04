# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::DpopToken, feature_category: :system_access do
  include Auth::DpopTokenHelper

  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user) }

  let(:dpop_proof) { generate_dpop_proof_for(user, alg: alg, typ: typ, kty: kty, fingerprint: fingerprint) }
  let(:data) { dpop_proof.proof }
  let(:alg) { Auth::DpopTokenHelper::VALID_ALG }
  let(:typ) { Auth::DpopTokenHelper::VALID_TYP }
  let(:kty) { Auth::DpopTokenHelper::VALID_KTY }
  let(:fingerprint) { nil }

  describe '#validate!' do
    subject(:validate!) { described_class.new(data: data).validate! }

    context 'when the token is valid' do
      it 'does not error' do
        expect { validate! }.not_to raise_error
      end
    end

    context 'when the token is invalid' do
      let(:data) { "this_is_obviously_not_a_valid_jwt" }

      it 'raises DpopValidationError' do
        expect do
          validate!
        end.to raise_error(Gitlab::Auth::DpopValidationError,
          /Malformed JWT, unable to decode. Not enough or too many segments/)
      end
    end

    context 'when the token is nil' do
      let(:data) { nil }

      it 'raises DpopValidationError' do
        expect do
          validate!
        end.to raise_error(Gitlab::Auth::DpopValidationError, /Malformed JWT, unable to decode. Nil JSON web token/)
      end
    end

    context 'when the typ is invalid' do
      let(:typ) { 'invalid' }

      it 'raises DpopValidationError' do
        expect do
          validate!
        end.to raise_error(Gitlab::Auth::DpopValidationError, /Invalid typ value in JWT/)
      end
    end

    context 'when the kid is missing' do
      let(:fingerprint) { '' }

      it 'raises DpopValidationError' do
        expect do
          validate!
        end.to raise_error(Gitlab::Auth::DpopValidationError, /No kid in JWT, unable to fetch key/)
      end
    end

    context 'when the alg is unsupported' do
      let(:alg) { 'RS256' }

      it 'raises DpopValidationError' do
        expect do
          validate!
        end.to raise_error(Gitlab::Auth::DpopValidationError, /Currently only RSA keys are supported/)
      end
    end

    context 'when the kid is invalid' do
      let(:fingerprint) { 'invalid' }

      it 'raises DpopValidationError' do
        expect do
          validate!
        end.to raise_error(Gitlab::Auth::DpopValidationError, /Malformed fingerprint value in kid/)
      end
    end

    context 'when the kid algorithm is unsupported' do
      let(:fingerprint) { 'SHA512:invalid' }

      it 'raises DpopValidationError' do
        expect do
          validate!
        end.to raise_error(Gitlab::Auth::DpopValidationError, /Unsupported fingerprint algorithm in kid/)
      end
    end

    context 'when the JWK algorithm is invalid' do
      let(:kty) { 'ABC' }

      it 'raises DpopValidationError' do
        expect do
          validate!
        end.to raise_error(Gitlab::Auth::DpopValidationError, /JWK algorithm must be RSA/)
      end
    end
  end
end
