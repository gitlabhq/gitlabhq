# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::DpopAuthenticationService, feature_category: :system_access do
  include Auth::DpopTokenHelper

  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user) }

  let(:dpop_proof) { generate_dpop_proof_for(user) }

  let(:headers) { { "dpop" => dpop_proof.proof } }
  let(:request) { instance_double(ActionDispatch::Request, headers: headers) }
  let(:service) do
    described_class.new(current_user: user, personal_access_token_plaintext: personal_access_token.token,
      request: request)
  end

  let(:dpop_enabled) { nil }

  before do
    user.user_preference.update!(dpop_enabled: dpop_enabled)
  end

  describe '#execute' do
    context 'when DPoP is not enabled for the user' do
      let(:dpop_enabled) { false }

      it 'succeeds' do
        expect(service.execute).to be_success
      end
    end

    context 'when DPoP is enabled' do
      let(:dpop_enabled) { true }

      context 'when the DPoP header is missing' do
        it 'raises a DpopValidationError' do
          headers.delete('dpop')

          expect { service.execute }.to raise_error(Gitlab::Auth::DpopValidationError, /DPoP header is missing/)
        end
      end

      context 'when an invalid DPoP header is provided' do
        it 'raises a DpopValidationError' do
          headers['dpop'] = 'invalid'

          expect do
            service.execute
          end.to raise_error(Gitlab::Auth::DpopValidationError, /Malformed JWT, unable to decode/)
        end
      end

      context 'when a valid DPoP header is provided' do
        it 'succeeds' do
          expect(service.execute).to be_success
        end
      end
    end
  end
end
