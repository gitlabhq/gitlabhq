# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  describe 'GET #discussions' do
    let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
    let_it_be(:commit) { project.commit_by(oid: sha) }

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: sha
      }
    end

    let(:send_request) { get discussions_namespace_project_commit_path(params) }

    before do
      sign_in(user)
    end

    context 'with a valid commit' do
      it 'returns all discussions in trimmed format' do
        create(:note_on_commit, project: project, commit_id: sha)

        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')

        json_response = Gitlab::Json.parse(response.body)
        expect(json_response).to have_key('discussions')
        expect(json_response['discussions']).to be_an(Array)

        # Check that the response doesn't contain the extra fields
        if json_response['discussions'].any?
          discussion = json_response['discussions'].first
          expect(discussion).to have_key('id')
          expect(discussion).to have_key('reply_id')
          expect(discussion).to have_key('confidential')
          expect(discussion).to have_key('diff_discussion')
          expect(discussion).to have_key('notes')

          # These fields should NOT be present in the trimmed response format
          expect(discussion).not_to have_key('project_id')
          expect(discussion).not_to have_key('commit_id')
          expect(discussion).not_to have_key('expanded')
          expect(discussion).not_to have_key('for_commit')
          expect(discussion).not_to have_key('individual_note')
          expect(discussion).not_to have_key('resolvable')
          expect(discussion).not_to have_key('truncated_diff_lines')
          expect(discussion).not_to have_key('active')
          expect(discussion).not_to have_key('line_code')
          expect(discussion).not_to have_key('diff_file')
          expect(discussion).not_to have_key('original_position')
          expect(discussion).not_to have_key('discussion_path')
          expect(discussion).not_to have_key('positions')
          expect(discussion).not_to have_key('line_codes')
        end
      end

      it 'returns empty discussions array when no discussions exist' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
        json_response = Gitlab::Json.parse(response.body)
        expect(json_response).to have_key('discussions')
        expect(json_response['discussions']).to eq([])
      end

      it 'includes both diff discussions and regular discussions' do
        # Create a regular note
        create(:note_on_commit, project: project, commit_id: sha)

        # Create a diff note
        create(:diff_note_on_commit, project: project, commit_id: sha)

        send_request

        expect(response).to have_gitlab_http_status(:ok)
        json_response = Gitlab::Json.parse(response.body)

        expect(json_response).to have_key('discussions')
        expect(json_response['discussions'].length).to eq(2)

        # Check we have both types
        discussions = json_response['discussions']
        diff_discussions = discussions.select { |d| d['diff_discussion'] }
        regular_discussions = discussions.reject { |d| d['diff_discussion'] }

        expect(diff_discussions).not_to be_empty
        expect(regular_discussions).not_to be_empty
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(rapid_diffs_on_commit_show: false)
        end

        it 'returns 404' do
          send_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

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

      expect(response).to render_template(:rapid_diffs)
    end

    it 'assigns files_changed_count' do
      send_request

      expect(assigns(:files_changed_count)).to eq(commit.stats.files)
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
