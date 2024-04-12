# frozen_string_literal: true

RSpec.shared_examples 'import controller status' do
  include ImportSpecHelper

  let(:group) { create(:group) }

  before do
    group.add_owner(user)
  end

  it "returns variables for json request" do
    project = create(:project, import_type: provider_name, creator_id: user.id)
    stub_client(client_repos_field => [repo])

    get :status, format: :json

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.dig("imported_projects", 0, "id")).to eq(project.id)
    expect(json_response.dig("provider_repos", 0, "id")).to eq(repo_id)
  end

  context 'when format is html' do
    context 'when namespace_id is present' do
      let!(:developer_group) { create(:group, developers: user) }

      context 'when user cannot import projects' do
        it 'returns 404' do
          get :status, params: { namespace_id: developer_group.id }, format: :html

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user can import projects' do
        it 'returns 200' do
          get :status, params: { namespace_id: group.id }, format: :html

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
