# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::OrgMover, feature_category: :organization do
  include GitlabShellHelpers

  let_it_be_with_reload(:organization) { create(:organization) }

  let(:public_key_path) { '/path/to/org_mover_public_key.pem' }
  let(:private_key) { OpenSSL::PKey::EC.generate('prime256v1') }
  let(:headers) { org_mover_headers(private_key) }
  let(:organization_id) { organization.id }

  before do
    stub_feature_flags(org_mover_maintenance_api: organization)
    stub_config_cell(enabled: true, id: 2)
    stub_config(org_mover: { public_key_files: [public_key_path] })
    allow(Gitlab::OrgMover::Authenticator).to receive(:read_public_key)
      .with(public_key_path).and_return(OpenSSL::PKey::EC.new(private_key.public_to_pem))
    Gitlab::OrgMover::Authenticator.clear_memoization(:jwks)
  end

  after do
    Gitlab::OrgMover::Authenticator.clear_memoization(:jwks)
  end

  def org_mover_headers(key, iat: Time.current.to_i)
    payload = {
      iss: Gitlab::OrgMover::Authenticator::JWT_ISSUER,
      aud: "#{Gitlab::OrgMover::Authenticator::JWT_AUDIENCE}:cell-2",
      iat: iat
    }

    { Gitlab::OrgMover::Authenticator::API_HEADER => JWT.encode(payload, key, 'ES256', { kid: kid_for(key) }) }
  end

  def kid_for(key)
    JWT::JWK.new(key, kid_generator: JWT::JWK::Thumbprint).kid
  end

  shared_examples 'an internal org_mover endpoint' do
    it 'logs the key that authenticated the request' do
      allow(Gitlab::AuthLogger).to receive(:info)

      request

      expect(Gitlab::AuthLogger).to have_received(:info).with({
        'message' => 'Org Mover request authenticated',
        jwt_kid: kid_for(private_key),
        jwt_iat: kind_of(Integer)
      })
    end

    context 'with a token signed by an untrusted key' do
      let(:headers) { org_mover_headers(OpenSSL::PKey::EC.generate('prime256v1')) }

      it 'returns 401 without logging an authenticated request', :aggregate_failures do
        allow(Gitlab::AuthLogger).to receive(:info)

        request

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(Gitlab::AuthLogger).not_to have_received(:info)
          .with(hash_including({ 'message' => 'Org Mover request authenticated' }))
      end
    end

    context 'with a gitlab-shell token' do
      let(:headers) { gitlab_shell_internal_api_request_header }

      it 'returns 401' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with an unknown organization' do
      let(:organization_id) { non_existing_record_id }

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the org_mover_maintenance_api flag is disabled for the organization' do
      it 'returns 404' do
        stub_feature_flags(org_mover_maintenance_api: false)

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /internal/org_mover/maintenance_state' do
    subject(:request) do
      get api('/internal/org_mover/maintenance_state'),
        params: { organization_id: organization_id }, headers: headers
    end

    it_behaves_like 'an internal org_mover endpoint'

    context 'when a public key file cannot be read' do
      it 'returns 500' do
        allow(Gitlab::OrgMover::Authenticator).to receive(:read_public_key).and_raise(Errno::ENOENT)

        request

        expect(response).to have_gitlab_http_status(:internal_server_error)
      end
    end

    context 'with a fractional iat' do
      let(:headers) { org_mover_headers(private_key, iat: Time.current.to_f - 1.5) }

      it 'logs iat as an integer' do
        allow(Gitlab::AuthLogger).to receive(:info)

        request

        expect(Gitlab::AuthLogger).to have_received(:info).with(hash_including({ jwt_iat: kind_of(Integer) }))
      end
    end

    it 'returns the current lifecycle state' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['state']).to eq('active')
    end

    it 'reflects the state after a transition' do
      organization.start_maintenance(maintenance_reason: 'migration')

      request

      expect(json_response['state']).to eq('maintenance_initialization')
    end
  end

  describe 'GET /internal/org_mover/maintenance_readiness' do
    subject(:request) do
      get api('/internal/org_mover/maintenance_readiness'),
        params: { organization_id: organization_id }, headers: headers
    end

    it_behaves_like 'an internal org_mover endpoint'

    it 'returns the readiness status and blocking reason' do
      stub_maintenance_readiness(false)

      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['ready']).to be(false)
      expect(json_response['blocking_reason']).to eq('pending migrations')
    end

    it 'returns a null blocking reason when ready' do
      stub_maintenance_readiness(true)

      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['ready']).to be(true)
      expect(json_response['blocking_reason']).to be_nil
    end
  end

  describe 'POST /internal/org_mover/start_maintenance' do
    let(:maintenance_reason) { 'migration' }

    subject(:request) do
      post api('/internal/org_mover/start_maintenance'),
        params: { organization_id: organization_id, maintenance_reason: maintenance_reason }, headers: headers
    end

    it_behaves_like 'an internal org_mover endpoint'

    it 'transitions the organization and returns 204' do
      expect { request }
        .to change { organization.reload.state }.from('active').to('maintenance_initialization')

      expect(response).to have_gitlab_http_status(:no_content)
    end

    context 'with an invalid maintenance_reason' do
      let(:maintenance_reason) { 'bogus' }

      it 'returns 400' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    it 'returns 422 when the organization is not active' do
      organization.start_maintenance(maintenance_reason: 'migration')
      organization.confirm_maintenance

      request

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it 'returns 204 no-op when already initializing maintenance' do
      organization.start_maintenance(maintenance_reason: 'migration')

      request

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  describe 'POST /internal/org_mover/confirm_maintenance' do
    subject(:request) do
      post api('/internal/org_mover/confirm_maintenance'),
        params: { organization_id: organization_id }, headers: headers
    end

    before do
      organization.start_maintenance(maintenance_reason: 'migration')
    end

    it_behaves_like 'an internal org_mover endpoint'

    it 'transitions the organization and returns 204' do
      stub_maintenance_readiness(true)

      expect { request }
        .to change { organization.reload.state }.from('maintenance_initialization').to('maintenance')

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 409 when the organization is not ready' do
      stub_maintenance_readiness(false)

      request

      expect(response).to have_gitlab_http_status(:conflict)
      expect(organization.reload.state).to eq('maintenance_initialization')
    end

    it 'returns 204 no-op when already in maintenance' do
      organization.confirm_maintenance

      request

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  describe 'POST /internal/org_mover/cancel_maintenance' do
    subject(:request) do
      post api('/internal/org_mover/cancel_maintenance'),
        params: { organization_id: organization_id }, headers: headers
    end

    before do
      organization.start_maintenance(maintenance_reason: 'migration')
    end

    it_behaves_like 'an internal org_mover endpoint'

    it 'transitions the organization back to active and returns 204' do
      expect { request }
        .to change { organization.reload.state }.from('maintenance_initialization').to('active')

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 204 no-op when already active' do
      organization.cancel_maintenance

      request

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  describe 'POST /internal/org_mover/exit_maintenance' do
    subject(:request) do
      post api('/internal/org_mover/exit_maintenance'),
        params: { organization_id: organization_id }, headers: headers
    end

    before do
      organization.start_maintenance(maintenance_reason: 'migration')
      organization.confirm_maintenance
    end

    it_behaves_like 'an internal org_mover endpoint'

    it 'transitions the organization back to active and returns 204' do
      expect { request }
        .to change { organization.reload.state }.from('maintenance').to('active')

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 204 no-op when already active' do
      organization.exit_maintenance

      request

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  def stub_maintenance_readiness(ready)
    allow_next_instance_of(Gitlab::Organizations::MaintenanceReadiness) do |readiness|
      allow(readiness).to receive(:blocking_reason).and_return(ready ? nil : 'pending migrations')
    end
  end
end
