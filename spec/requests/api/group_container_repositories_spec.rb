# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupContainerRepositories, feature_category: :container_registry do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:root_repository) { create(:container_repository, :root, project: project) }
  let(:test_repository) { create(:container_repository, project: project) }

  let(:users) do
    {
      anonymous: nil,
      guest: guest,
      reporter: reporter
    }
  end

  let(:api_user) { reporter }
  let(:params) { {} }

  before do
    group.add_reporter(reporter)
    group.add_guest(guest)

    stub_container_registry_config(enabled: true)
    stub_container_registry_info

    root_repository
    test_repository
  end

  describe 'GET /groups/:id/registry/repositories' do
    let(:url) { "/groups/#{group.id}/registry/repositories" }
    let(:snowplow_gitlab_standard_context) do
      { user: api_user, namespace: group, property: 'i_package_container_user' }
    end

    subject { get api(url, api_user) }

    it_behaves_like 'rejected container repository access', :guest, :forbidden
    it_behaves_like 'rejected container repository access', :anonymous, :not_found

    it_behaves_like 'returns repositories for allowed users', :reporter, 'group' do
      let(:object) { group }
    end

    it_behaves_like 'a package tracking event', described_class.name, 'list_repositories'

    context 'with invalid group id' do
      let(:url) { "/groups/#{non_existing_record_id}/registry/repositories" }

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with URL-encoded path of the group' do
      let(:url) { "/groups/#{group.full_path}/registry/repositories" }

      it_behaves_like 'rejected container repository access', :guest, :forbidden
      it_behaves_like 'rejected container repository access', :anonymous, :not_found
      it_behaves_like 'returns repositories for allowed users', :reporter
    end
  end
end
