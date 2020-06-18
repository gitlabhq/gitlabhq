# frozen_string_literal: true

RSpec.shared_examples 'import controller with new_import_ui feature flag' do
  include ImportSpecHelper

  context 'with new_import_ui feature flag enabled' do
    let(:group) { create(:group) }

    before do
      stub_feature_flags(new_import_ui: true)
      group.add_owner(user)
    end

    it "returns variables for json request" do
      project = create(:project, import_type: provider_name, creator_id: user.id)
      stub_client(client_repos_field => [repo])

      get :status, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.dig("imported_projects", 0, "id")).to eq(project.id)
      expect(json_response.dig("provider_repos", 0, "id")).to eq(repo_id)
      expect(json_response.dig("namespaces", 0, "id")).to eq(group.id)
    end

    it "does not show already added project" do
      project = create(:project, import_type: provider_name, namespace: user.namespace, import_status: :finished, import_source: import_source)
      stub_client(client_repos_field => [repo])

      get :status, format: :json

      expect(json_response.dig("imported_projects", 0, "id")).to eq(project.id)
      expect(json_response.dig("provider_repos")).to eq([])
    end
  end
end
