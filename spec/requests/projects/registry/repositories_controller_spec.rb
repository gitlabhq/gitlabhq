# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Registry::RepositoriesController, feature_category: :container_registry do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user, developer_of: project) }

  before do
    stub_container_registry_config(enabled: true, key: 'spec/fixtures/x509_certificate_pk.key')
    stub_container_registry_info

    sign_in(user)
    allow(Auth::ContainerRegistryAuthenticationService).to receive(:access_token).with({}).and_return('foo')
  end

  describe 'GET #index' do
    subject(:index_response) do
      get project_container_registry_index_path(project)
      response
    end

    it 'renders the page with its title' do
      expect(index_response).to have_gitlab_http_status(:ok)
      expect(index_response.body).to include("<title>#{_('Container registry')}")
    end

    it_behaves_like 'container registry app root with registry errors'
  end

  describe 'GET #show' do
    let_it_be(:container_repository) { create(:container_repository, :root, project: project) }

    subject do
      get project_container_registry_path(project, container_repository)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }
  end
end
