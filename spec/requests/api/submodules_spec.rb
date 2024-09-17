# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Submodules, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:guest) { create(:user) { |u| project.add_guest(u) } }
  let(:submodule) { 'six' }
  let(:commit_sha) { 'e25eda1fece24ac7a03624ed1320f82396f35bd8' }
  let(:branch) { 'master' }
  let(:commit_message) { 'whatever' }

  let(:params) do
    {
      submodule: submodule,
      commit_sha: commit_sha,
      branch: branch,
      commit_message: commit_message
    }
  end

  before do
    project.add_developer(user)
  end

  def route(submodule = nil)
    "/projects/#{project.id}/repository/submodules/#{submodule}"
  end

  describe "PUT /projects/:id/repository/submodule/:submodule" do
    context 'when unauthenticated' do
      it 'returns 401' do
        put api(route(submodule)), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated', 'as a guest' do
      it 'returns 403' do
        put api(route(submodule), guest), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated', 'as a developer' do
      it 'returns 400 if params is missing' do
        put api(route(submodule), user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 if branch is missing' do
        put api(route(submodule), user), params: params.except(:branch)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 if commit_sha is missing' do
        put api(route(submodule), user), params: params.except(:commit_sha)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns the commit' do
        head_commit = project.repository.commit.id

        put api(route(submodule), user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['message']).to eq commit_message
        expect(json_response['author_name']).to eq user.name
        expect(json_response['committer_name']).to eq user.name
        expect(json_response['parent_ids'].first).to eq head_commit
      end

      context 'when the submodule name is urlencoded' do
        let(:submodule) { 'test_inside_folder/another_folder/six' }
        let(:branch) { 'submodule_inside_folder' }
        let(:encoded_submodule) { CGI.escape(submodule) }

        it 'returns the commit' do
          expect(Submodules::UpdateService)
            .to receive(:new)
                  .with(any_args, hash_including(submodule: submodule))
                  .and_call_original

          put api(route(encoded_submodule), user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq project.repository.commit(branch).id
          expect(project.repository.blob_at(branch, submodule).id).to eq commit_sha
        end
      end

      context 'when the submodule name contains a dot' do
        let(:branch) { 'submodule-with-dot' }
        let(:submodule) { '.dot-submodule' }
        let(:commit_sha) { '272ff231b7c36f7d0fdbfb55cb3c1856bd8014ae' }

        it 'returns the commit' do
          expect(Submodules::UpdateService)
            .to receive(:new)
                  .with(any_args, hash_including(submodule: submodule))
                  .and_call_original

          put api(route(submodule), user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq project.repository.commit(branch).id
          expect(project.repository.blob_at(branch, submodule).id).to eq commit_sha
        end
      end
    end
  end
end
