# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  describe '#rapid_diffs' do
    let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
    let_it_be(:commit) { project.commit_by(oid: sha) }
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
  end

  describe 'GET #diff_files_metadata' do
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: sha
      }
    end

    let(:send_request) { get diff_files_metadata_namespace_project_commit_path(params) }

    before do
      sign_in(user)
    end

    context 'with valid params' do
      let(:sha) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }

      include_examples 'diff files metadata'
    end

    context 'with invalid params' do
      let(:sha) { '0123456789' }

      include_examples 'missing diff files metadata'
    end
  end

  describe 'GET #diffs_stats' do
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: sha
      }
    end

    let(:send_request) { get diffs_stats_namespace_project_commit_path(params) }

    before do
      sign_in(user)
    end

    context 'with valid params' do
      let(:sha) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }

      include_examples 'diffs stats' do
        let(:expected_stats) do
          {
            added_lines: 645,
            removed_lines: 0,
            diffs_count: 6
          }
        end
      end

      context 'when diffs overflow' do
        include_examples 'overflow' do
          let(:expected_stats) do
            {
              visible_count: 6,
              email_path: "/#{project.full_path}/-/commit/#{sha}.patch",
              diff_path: "/#{project.full_path}/-/commit/#{sha}.diff"
            }
          end
        end
      end
    end

    context 'with invalid params' do
      let(:sha) { '0123456789' }

      include_examples 'missing diffs stats'
    end
  end

  describe 'GET #diff_files' do
    let(:master_pickable_sha) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }
    let(:format) { :html }
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: master_pickable_sha,
        format: format
      }
    end

    before_all do
      project.add_maintainer(user)
    end

    context 'without expanded parameter' do
      before do
        sign_in(user)
      end

      it 'does not rate limit the endpoint' do
        get diff_files_namespace_project_commit_url(params)

        expect(::Gitlab::ApplicationRateLimiter)
          .not_to receive(:throttled?).with(:expanded_diff_files, scope: user)
      end
    end

    context 'with expanded parameter' do
      before do
        params[:expanded] = 1
      end

      context 'with signed in user' do
        it_behaves_like 'rate limited endpoint', rate_limit_key: :expanded_diff_files, use_second_scope: false do
          let(:current_user) { user }

          before do
            sign_in current_user
          end

          def request
            get diff_files_namespace_project_commit_url(params)
          end
        end
      end

      context 'without a signed in user' do
        it_behaves_like 'rate limited endpoint', rate_limit_key: :expanded_diff_files do
          let_it_be(:project) { create(:project, :public, :repository) }
          let(:request_ip) { '1.2.3.4' }

          def request
            get diff_files_namespace_project_commit_url(params),
              params: { scope: request_ip }, env: { REMOTE_ADDR: request_ip }
          end

          def request_with_second_scope
            get diff_files_namespace_project_commit_url(params), env: { REMOTE_ADDR: '1.2.3.5' }
          end
        end
      end
    end
  end

  describe 'GET #diff_file' do
    let(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
    let(:commit) { project.commit_by(oid: sha) }
    let(:diff_file_path) do
      diff_file_namespace_project_commit_path(namespace_id: project.namespace, project_id: project, id: sha)
    end

    let(:diff_file) { commit.diffs.diff_files.first }
    let(:old_path) { diff_file.old_path }
    let(:new_path) { diff_file.new_path }
    let(:ignore_whitespace_changes) { false }
    let(:view) { 'inline' }

    let(:params) do
      {
        old_path: old_path,
        new_path: new_path,
        ignore_whitespace_changes: ignore_whitespace_changes,
        view: view
      }.compact
    end

    let(:send_request) { get diff_file_path, params: params }

    before do
      sign_in(user)
    end

    include_examples 'diff file endpoint'

    context 'with whitespace-only diffs' do
      let(:ignore_whitespace_changes) { true }
      let(:diffs_collection) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }

      before do
        allow(diff_file).to receive(:whitespace_only?).and_return(true)
      end

      it 'makes a call to diffs_resource with ignore_whitespace_change: false' do
        expect_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:diffs_resource).and_return(diffs_collection)

          expect(instance).to receive(:diffs_resource).with(
            hash_including(ignore_whitespace_change: false)
          ).and_return(diffs_collection)
        end

        send_request

        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end
end
