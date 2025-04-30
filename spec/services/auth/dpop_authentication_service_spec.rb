# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::DpopAuthenticationService, :aggregate_failures, feature_category: :system_access do
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

  shared_examples "failed dpop checks after DPoP is enforced" do
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

  shared_examples "user-level DPoP is enabled" do
    let_it_be(:dpop_enabled) { true }

    context 'when a valid DPoP header is provided' do
      it 'returns success and enforces DPoP on a user' do
        expect(service_execute_with_enforce_dpop_authentication).to be_success
      end
    end

    context 'when invalid DPoP header(s) is/are provided' do
      it_behaves_like "failed dpop checks after DPoP is enforced"
    end
  end

  shared_examples "user-level DPoP is disabled" do
    let_it_be(:dpop_enabled) { false }

    it 'returns success but does not enforce DPoP on a user' do
      expect(service.execute).to be_success

      service.execute
      expect(Gitlab::Auth::DpopTokenUser).not_to receive(:new)
    end
  end

  describe '#execute' do
    describe 'User-level DPoP enforcement' do
      let(:enforce_dpop_authentication) { false } # Same result if true as the group will not apply

      context 'when user-level DPoP is disabled' do
        it_behaves_like 'user-level DPoP is disabled'
      end

      context 'when user-level DPoP is enabled' do
        it_behaves_like 'user-level DPoP is enabled'
      end
    end

    describe 'Group-level DPoP enforcement to a `/manage` endpoint' do
      context 'when User-level DPoP is disabled' do
        context 'when its not a `/manage` endpoint (enforce_dpop_authentication=false)' do
          let(:enforce_dpop_authentication) { false }

          before do
            group.update!(require_dpop_for_manage_api_endpoints: true)
          end

          it_behaves_like 'user-level DPoP is disabled'
        end

        context 'when group-level DPoP is not enforced (require_dpop_for_manage_api_endpoints=false)' do
          let(:enforce_dpop_authentication) { true }

          before do
            group.update!(require_dpop_for_manage_api_endpoints: false)
          end

          it_behaves_like 'user-level DPoP is disabled'
        end

        context 'when enforce_dpop_authentication AND require_dpop_for_manage_api_endpoints are true' do
          let(:enforce_dpop_authentication) { true }

          before do
            group.update!(require_dpop_for_manage_api_endpoints: true)
          end

          it_behaves_like 'user-level DPoP is enabled'
        end
      end

      context 'when User-level DPoP is enabled' do
        context 'when its not a `/manage` endpoint (enforce_dpop_authentication=false)' do
          let(:enforce_dpop_authentication) { false }

          before do
            group.update!(require_dpop_for_manage_api_endpoints: true)
          end

          it_behaves_like 'user-level DPoP is enabled'
        end

        context 'when group-level DPoP is not enforced (require_dpop_for_manage_api_endpoints=false)' do
          let(:enforce_dpop_authentication) { true }

          before do
            group.update!(require_dpop_for_manage_api_endpoints: false)
          end

          it_behaves_like 'user-level DPoP is enabled'
        end

        context 'when enforce_dpop_authentication AND require_dpop_for_manage_api_endpoints are true' do
          let(:enforce_dpop_authentication) { true }

          before do
            group.update!(require_dpop_for_manage_api_endpoints: true)
          end

          it_behaves_like 'user-level DPoP is enabled'
        end
      end
    end
  end
end
