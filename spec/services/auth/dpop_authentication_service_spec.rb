# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::DpopAuthenticationService, feature_category: :system_access do
  include Auth::DpopTokenHelper

  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user) }
  let_it_be(:group) { create(:group) }

  let(:dpop_proof) { generate_dpop_proof_for(user) }

  let(:headers) { { "dpop" => dpop_proof.proof } }
  let(:request) { instance_double(ActionDispatch::Request, headers: headers) }
  let(:service) do
    described_class.new(current_user: user, personal_access_token_plaintext: personal_access_token.token,
      request: request)
  end

  let(:service_execute_with_enforce_dpop_authentication) do
    service.execute(enforce_dpop_authentication: enforce_dpop_authentication, group_id: group.id)
  end

  let(:dpop_enabled) { nil }

  before do
    user.user_preference.update!(dpop_enabled: dpop_enabled)
  end

  shared_examples "failed dpop check" do
    context 'when the DPoP header is missing' do
      it 'raises a DpopValidationError' do
        headers.delete('dpop')

        expect do
          service_execute_with_enforce_dpop_authentication
        end.to raise_error(
          Gitlab::Auth::DpopValidationError, /DPoP header is missing/)
      end
    end

    context 'when an invalid DPoP header is provided' do
      it 'raises a DpopValidationError' do
        headers['dpop'] = 'invalid'

        expect do
          service_execute_with_enforce_dpop_authentication
        end.to raise_error(Gitlab::Auth::DpopValidationError, /Malformed JWT, unable to decode/)
      end
    end

    context 'when two DPoP headers are provided' do
      it 'raises a DpopValidationError' do
        # Rails concatenates duplicate headers with a comma
        headers['dpop'] = "#{dpop_proof.proof}, #{dpop_proof.proof}"

        expect do
          service_execute_with_enforce_dpop_authentication
        end.to raise_error(Gitlab::Auth::DpopValidationError, /Only 1 DPoP header is allowed in request/)
      end
    end
  end

  describe '#execute' do
    context 'when DPoP is not enabled for the user' do
      let(:dpop_enabled) { false }

      context 'when enforce_dpop_authentication false' do
        it 'succeeds' do
          expect(service.execute).to be_success
        end
      end

      context 'when enforce_dpop_authentication true' do
        let(:enforce_dpop_authentication) { true }

        context 'when group setting require_dpop_for_manage_api_endpoints is true' do
          before do
            group.update!(require_dpop_for_manage_api_endpoints: true)
          end

          it_behaves_like "failed dpop check"
        end

        context 'when group setting require_dpop_for_manage_api_endpoints is false' do
          before do
            group.update!(require_dpop_for_manage_api_endpoints: false)
          end

          it 'succeeds' do
            expect(service_execute_with_enforce_dpop_authentication).to be_success
          end
        end
      end
    end

    context 'when DPoP is enabled' do
      let(:dpop_enabled) { true }
      let(:enforce_dpop_authentication) { false }

      context 'when a valid DPoP header is provided' do
        it 'succeeds' do
          expect(service.execute).to be_success
        end

        context 'when enforce_dpop_authentication is passed as true' do
          let(:enforce_dpop_authentication) { true }

          it "does not impact the DPoP check and response is success" do
            expect(service_execute_with_enforce_dpop_authentication).to be_success
          end
        end
      end
    end
  end
end
