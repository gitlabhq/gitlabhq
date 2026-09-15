# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::OrgMover, feature_category: :organization do
  include GitlabShellHelpers

  let_it_be_with_reload(:organization) { create(:organization) }

  let(:headers) { gitlab_shell_internal_api_request_header }
  let(:organization_id) { organization.id }

  before do
    stub_feature_flags(org_mover_maintenance_api: organization)
  end

  shared_examples 'an internal org_mover endpoint' do
    context 'with an invalid gitlab-shell token' do
      let(:headers) { gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse') }

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

    it 'returns the readiness status' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['ready']).to be(false)
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
      allow_next_instance_of(Gitlab::Organizations::MaintenanceReadiness) do |readiness|
        allow(readiness).to receive(:ready?).and_return(true)
      end

      expect { request }
        .to change { organization.reload.state }.from('maintenance_initialization').to('maintenance')

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 409 when the organization is not ready' do
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
end
