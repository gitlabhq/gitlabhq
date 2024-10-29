# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitController, feature_category: :source_code_management do
  describe '#rapid_diffs' do
    let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:commit) { project.commit_by(oid: sha) }
    let_it_be(:user) { project.owner }
    let_it_be(:diff_view) { :inline }

    let(:params) do
      {
        rapid_diffs: 'true',
        view: diff_view
      }
    end

    subject(:send_request) { get project_commit_path(project, commit, params: params) }

    before do
      sign_in(user)
    end

    context 'when the feature flag rapid_diffs is disabled' do
      before do
        stub_feature_flags(rapid_diffs: false)
      end

      it 'returns 404' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'uses show action when rapid_diffs query parameter doesnt exist' do
        get project_commit_path(project, commit)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('data-page="projects:commit:show"')
      end
    end

    it 'returns 200' do
      send_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('data-page="projects:commit:rapid_diffs"')
    end

    it 'uses show action when rapid_diffs query parameter doesnt exist' do
      get project_commit_path(project, commit)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('data-page="projects:commit:show"')
    end

    it 'shows only first 5 files' do
      send_request

      expect(response.body.scan('<diff-file ').size).to eq(5)
    end

    it 'renders rapid_diffs template' do
      send_request

      expect(assigns(:diffs)).to be_a(Gitlab::Diff::FileCollection::Commit)
      expect(assigns(:environment)).to be_nil
      expect(response).to render_template(:rapid_diffs)
    end

    context 'for stream_url' do
      it 'returns stream_url with offset' do
        send_request

        url = "/#{project.full_path}/-/commit/#{commit.id}/diffs_stream?offset=5&view=inline"

        expect(assigns(:stream_url)).to eq(url)
      end

      context 'when view is set to parallel' do
        let_it_be(:diff_view) { :parallel }

        it 'returns stream_url with parallel view' do
          send_request

          url = "/#{project.full_path}/-/commit/#{commit.id}/diffs_stream?offset=5&view=parallel"

          expect(assigns(:stream_url)).to eq(url)
        end
      end
    end
  end
end
