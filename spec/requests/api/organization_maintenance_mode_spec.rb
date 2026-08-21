# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/SpecFilePathFormat -- Spec path requested for cross-API helper behavior coverage.
RSpec.describe API::Projects, :with_current_organization, :without_current_organization, feature_category: :organization do
  let_it_be_with_reload(:maintenance_mode_organization) { create(:organization) }
  let_it_be(:active_organization) { create(:organization) }
  let_it_be(:user) { create(:user, organization: maintenance_mode_organization) }
  let_it_be(:active_user) { create(:user, organization: active_organization) }
  let_it_be(:namespace) { create(:namespace, owner: user, organization: maintenance_mode_organization) }
  let_it_be(:active_namespace) { create(:namespace, owner: active_user, organization: active_organization) }
  let_it_be(:project) do
    create(:project, :public, namespace: namespace, organization: maintenance_mode_organization)
  end

  let_it_be(:group) { create(:group, :private, organization: maintenance_mode_organization, maintainers: user) }

  let(:headers) { { Gitlab::Current::Organization::HTTP_HEADER => maintenance_mode_organization.id.to_s } }
  let(:maintenance_mode_message) do
    _('This organization is temporarily unavailable due to maintenance.')
  end

  let(:indefinite_maintenance_mode_message) do
    _('This organization is unavailable.')
  end

  before_all do
    project.add_maintainer(user)
    maintenance_mode_organization.start_maintenance(maintenance_reason: 'migration')
    maintenance_mode_organization.confirm_maintenance
  end

  shared_examples 'a maintenance mode organization blocked request' do
    it 'returns service unavailable with a Retry-After header', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(:service_unavailable)
      expect(json_response['message']).to eq(maintenance_mode_message)
      expect(response.headers['Retry-After']).to eq('60')
    end
  end

  context 'when organization maintenance enforcement is enabled' do
    before do
      stub_feature_flags(organization_maintenance_enforcement: true)
    end

    describe 'POST /projects' do
      let(:request) do
        post api('/projects', user), params: { name: 'maintenance mode project' }, headers: headers
      end

      it_behaves_like 'a maintenance mode organization blocked request'
    end

    describe 'GET /projects/:id' do
      let(:request) do
        get api("/projects/#{project.id}", user), headers: headers
      end

      it_behaves_like 'a maintenance mode organization blocked request'
    end

    describe 'POST /projects/:id/issues' do
      let(:request) do
        post api("/projects/#{project.id}/issues", user),
          params: { title: 'maintenance mode issue' },
          headers: headers
      end

      it_behaves_like 'a maintenance mode organization blocked request'
    end

    describe 'GET /projects/:id/issues' do
      let(:request) do
        get api("/projects/#{project.id}/issues", user), headers: headers
      end

      it_behaves_like 'a maintenance mode organization blocked request'
    end

    describe 'POST /groups/:id/milestones' do
      let(:request) do
        post api("/groups/#{group.id}/milestones", user),
          params: { title: 'maintenance mode milestone' },
          headers: headers
      end

      it_behaves_like 'a maintenance mode organization blocked request'
    end

    describe 'GET /namespaces/:id' do
      let(:request) do
        get api("/namespaces/#{namespace.id}", user), headers: headers
      end

      it_behaves_like 'a maintenance mode organization blocked request'
    end

    describe 'GET /groups/:id/work_items resolved by full path' do
      let(:request) do
        get api("/groups/#{group.full_path}/work_items", user), headers: headers
      end

      it_behaves_like 'a maintenance mode organization blocked request'
    end

    context 'when the organization is in maintenance mode for an indefinite reason' do
      let_it_be_with_reload(:indefinite_organization) { create(:organization) }
      let_it_be(:indefinite_user) { create(:user, organization: indefinite_organization) }
      let_it_be(:indefinite_namespace) do
        create(:namespace, owner: indefinite_user, organization: indefinite_organization)
      end

      let_it_be(:indefinite_project) do
        create(:project, :public, namespace: indefinite_namespace, organization: indefinite_organization)
      end

      let(:indefinite_headers) do
        { Gitlab::Current::Organization::HTTP_HEADER => indefinite_organization.id.to_s }
      end

      before_all do
        indefinite_project.add_maintainer(indefinite_user)
        indefinite_organization.start_maintenance(maintenance_reason: 'legal')
        indefinite_organization.confirm_maintenance
      end

      it 'blocks write requests with forbidden and no Retry-After header', :aggregate_failures do
        post api('/projects', indefinite_user),
          params: { name: 'indefinite maintenance mode project' },
          headers: indefinite_headers

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to include(indefinite_maintenance_mode_message)
        expect(response.headers['Retry-After']).to be_nil
      end

      it 'blocks read requests with forbidden and no Retry-After header', :aggregate_failures do
        get api("/projects/#{indefinite_project.id}", indefinite_user), headers: indefinite_headers

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to include(indefinite_maintenance_mode_message)
        expect(response.headers['Retry-After']).to be_nil
      end
    end

    context 'when the organization is active' do
      it 'allows write requests' do
        post api('/projects', active_user),
          params: { name: 'active project' },
          headers: { Gitlab::Current::Organization::HTTP_HEADER => active_organization.id.to_s }

        expect(response).to have_gitlab_http_status(:created)
      end
    end
  end

  context 'when organization maintenance enforcement is disabled' do
    before do
      stub_feature_flags(organization_maintenance_enforcement: false)
    end

    it 'allows write requests for maintenance mode organizations' do
      post api('/projects', user), params: { name: 'disabled enforcement project' }, headers: headers

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'allows read requests for maintenance mode organizations' do
      get api("/projects/#{project.id}", user), headers: headers

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
