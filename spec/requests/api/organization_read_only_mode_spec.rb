# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/SpecFilePathFormat -- Spec path requested for cross-API helper behavior coverage.
RSpec.describe API::Projects, :with_current_organization, :without_current_organization, feature_category: :organization do
  let_it_be_with_reload(:read_only_organization) { create(:organization) }
  let_it_be(:active_organization) { create(:organization) }
  let_it_be(:user) { create(:user, organization: read_only_organization) }
  let_it_be(:active_user) { create(:user, organization: active_organization) }
  let_it_be(:namespace) { create(:namespace, owner: user, organization: read_only_organization) }
  let_it_be(:active_namespace) { create(:namespace, owner: active_user, organization: active_organization) }
  let_it_be(:project) { create(:project, :public, namespace: namespace, organization: read_only_organization) }
  let_it_be(:group) { create(:group, :private, organization: read_only_organization, maintainers: user) }

  let(:headers) { { Gitlab::Current::Organization::HTTP_HEADER => read_only_organization.id.to_s } }
  let(:read_only_message) do
    _('This organization is currently in read-only mode. Write operations are temporarily disabled.')
  end

  let(:indefinite_read_only_message) do
    _('This organization is currently in read-only mode. Write operations are disabled.')
  end

  before_all do
    project.add_maintainer(user)
    read_only_organization.start_read_only(read_only_reason: 'migration')
    read_only_organization.confirm_read_only
  end

  shared_examples 'a read-only organization write request' do
    it 'returns service unavailable with a Retry-After header', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(:service_unavailable)
      expect(json_response['message']).to eq(read_only_message)
      expect(response.headers['Retry-After']).to eq('60')
    end
  end

  context 'when organization read-only enforcement is enabled' do
    before do
      stub_feature_flags(organization_read_only_enforcement: true)
    end

    describe 'POST /projects' do
      let(:request) do
        post api('/projects', user), params: { name: 'read-only project' }, headers: headers
      end

      it_behaves_like 'a read-only organization write request'
    end

    describe 'GET /projects/:id' do
      it 'allows read requests' do
        get api("/projects/#{project.id}", user), headers: headers

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'POST /projects/:id/issues' do
      let(:request) do
        post api("/projects/#{project.id}/issues", user),
          params: { title: 'read-only issue' },
          headers: headers
      end

      it_behaves_like 'a read-only organization write request'
    end

    describe 'GET /projects/:id/issues' do
      it 'allows read requests' do
        get api("/projects/#{project.id}/issues", user), headers: headers

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'POST /groups/:id/milestones' do
      let(:request) do
        post api("/groups/#{group.id}/milestones", user),
          params: { title: 'read-only milestone' },
          headers: headers
      end

      it_behaves_like 'a read-only organization write request'
    end

    context 'when the organization is read-only for an indefinite reason' do
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
        indefinite_organization.start_read_only(read_only_reason: 'legal')
        indefinite_organization.confirm_read_only
      end

      it 'returns forbidden without a Retry-After header', :aggregate_failures do
        post api('/projects', indefinite_user),
          params: { name: 'indefinite read-only project' },
          headers: indefinite_headers

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to include(indefinite_read_only_message)
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

  context 'when organization read-only enforcement is disabled' do
    before do
      stub_feature_flags(organization_read_only_enforcement: false)
    end

    it 'allows write requests for read-only organizations' do
      post api('/projects', user), params: { name: 'disabled enforcement project' }, headers: headers

      expect(response).to have_gitlab_http_status(:created)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
