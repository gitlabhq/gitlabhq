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
          expect(discussion).to have_key('individual_note')
          expect(discussion).to have_key('notes')

          # These fields should NOT be present in the trimmed response format
          expect(discussion).not_to have_key('project_id')
          expect(discussion).not_to have_key('commit_id')
          expect(discussion).not_to have_key('expanded')
          expect(discussion).not_to have_key('for_commit')
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

  describe 'POST #create_discussions' do
    let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
    let_it_be(:commit) { project.commit_by(oid: sha) }

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: sha
      }
    end

    let(:send_request) { post discussions_namespace_project_commit_path(params), params: request_params }

    before do
      sign_in(user)
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(rapid_diffs_on_commit_show: false)
      end

      let(:request_params) { { note: { note: 'Test note' } } }

      it 'returns 404' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user cannot create notes' do
      let(:request_params) { { note: { note: 'Test note' } } }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :create_note, anything).and_return(false)
      end

      it 'does not allow note creation' do
        expect { send_request }.not_to change { Note.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when creating a timeline discussion' do
      let(:request_params) do
        {
          note: {
            note: 'This is a timeline discussion'
          }
        }
      end

      it 'creates a new discussion successfully' do
        expect { send_request }.to change { Note.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')

        json_response = Gitlab::Json.parse(response.body)
        expect(json_response).to have_key('discussion')

        discussion = json_response['discussion']
        expect(discussion).to have_key('id')
        expect(discussion).to have_key('notes')
        expect(discussion[:individual_note]).to be_falsy
        expect(discussion['notes'].first['note']).to eq('This is a timeline discussion')
      end
    end

    context 'when creating a positioned discussion' do
      let(:diff_file) { commit.diffs.diff_files.find { |f| f.new_path == 'files/ruby/popen.rb' } }
      let(:position_data) do
        {
          old_line: nil,
          new_line: 14,
          new_path: diff_file.new_path,
          old_path: diff_file.old_path
        }
      end

      let(:request_params) do
        {
          note: {
            note: 'This is a positioned discussion',
            position: position_data
          }
        }
      end

      it 'creates a positioned discussion successfully' do
        expect { send_request }.to change { Note.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        json_response = Gitlab::Json.parse(response.body)

        discussion = json_response['discussion']
        expect(discussion['diff_discussion']).to be true
        expect(discussion['notes'].first['note']).to eq('This is a positioned discussion')
      end

      context 'with image comment' do
        let(:position_data) do
          {
            new_path: diff_file.new_path,
            old_path: diff_file.old_path,
            position_type: 'image',
            width: 10,
            height: 10,
            x: 5,
            y: 2
          }
        end

        it 'creates a positioned discussion successfully' do
          expect { send_request }.to change { Note.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)
          json_response = Gitlab::Json.parse(response.body)

          discussion = json_response['discussion']
          expect(discussion['diff_discussion']).to be true
          expect(discussion['notes'].first['note']).to eq('This is a positioned discussion')
          expect(discussion['notes'].first['position']['position_type']).to eq('image')
        end
      end

      context 'on a deleted line' do
        let_it_be(:sha) { "d59c60028b053793cecfb4022de34602e1a9218e" }
        let(:diff_file) { commit.diffs.diff_files.find { |f| f.old_path == 'files/js/commit.js.coffee' } }

        let(:position_data) do
          {
            old_line: 1,
            new_line: nil,
            new_path: diff_file.new_path,
            old_path: diff_file.old_path
          }
        end

        let(:request_params) do
          {
            note: {
              note: 'Comment on deleted line',
              position: position_data
            }
          }
        end

        it 'creates a positioned discussion on old line' do
          expect { send_request }.to change { Note.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)
          json_response = Gitlab::Json.parse(response.body)

          discussion = json_response['discussion']
          expect(discussion['diff_discussion']).to be true
          expect(discussion['notes'].first['note']).to eq('Comment on deleted line')
        end
      end

      context 'with incomplete position data' do
        let(:position_data) do
          {
            old_path: 'files/ruby/popen.rb'
          }
        end

        it 'returns validation error from Notes::CreateService' do
          send_request

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          json_response = Gitlab::Json.parse(response.body)
          expect(json_response).to have_key('errors')
        end
      end

      context 'with explicit DiffNote type' do
        let(:request_params) do
          {
            note: {
              note: 'This is a positioned discussion',
              type: 'DiffNote',
              position: position_data
            }
          }
        end

        it 'creates a positioned discussion with provided DiffNote type' do
          expect { send_request }.to change { Note.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)
          json_response = Gitlab::Json.parse(response.body)
          expect(json_response['discussion']['diff_discussion']).to be true
        end
      end
    end

    context 'when replying to existing DiffNote discussion' do
      let!(:existing_note) { create(:diff_note_on_commit, project: project, commit_id: sha) }

      let(:request_params) do
        {
          note: {
            note: 'This is a reply'
          },
          in_reply_to_discussion_id: existing_note.discussion_id
        }
      end

      it 'creates a reply to existing discussion' do
        expect { send_request }.to change { Note.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        json_response = Gitlab::Json.parse(response.body)

        discussion = json_response['discussion']
        expect(discussion['id']).to eq(existing_note.discussion_id)
        expect(discussion['diff_discussion']).to be true
        expect(discussion['notes'].length).to eq(2)

        original_note = discussion['notes'].first
        expect(original_note['id']).to eq(existing_note.id.to_s)

        reply_note = discussion['notes'].second
        expect(reply_note['note']).to eq('This is a reply')
        expect(reply_note['discussion_id']).to eq(existing_note.discussion_id)
      end

      context 'with non-existent discussion ID' do
        let(:request_params) do
          {
            note: {
              note: 'This is a reply',
              type: 'DiscussionNote'
            },
            in_reply_to_discussion_id: 'non-existent-id'
          }
        end

        it 'returns discussion not found error' do
          send_request

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          json_response = Gitlab::Json.parse(response.body)
          expect(json_response['errors']).to eq('Discussion not found')
        end
      end
    end
  end

  describe '#show' do
    let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
    let_it_be(:commit) { project.commit_by(oid: sha) }
    let_it_be(:diff_view) { :inline }

    let(:params) do
      { view: diff_view }
    end

    subject(:send_request) { get project_commit_path(project, commit, params: params) }

    before do
      sign_in(user)
    end

    it 'returns 200' do
      send_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('data-rapid-diffs')
    end

    it 'shows only first 5 files' do
      send_request

      expect(response.body.scan('<diff-file ').size).to eq(5)
    end

    it 'renders rapid_diffs template' do
      send_request

      expect(response).to render_template(:rapid_diffs)
    end

    it 'renders legacy template' do
      stub_feature_flags(rapid_diffs_on_commit_show: false)
      send_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
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

      before do
        allow(diff_file).to receive(:whitespace_only?).and_return(true)
      end

      it 'makes a call to presenter diff_files with ignore_whitespace_change: false' do
        expect_next_instance_of(RapidDiffs::CommitPresenter) do |presenter|
          allow(presenter).to receive(:diff_files).and_return([diff_file])

          expect(presenter).to receive(:diff_files).with(
            hash_including(ignore_whitespace_change: false)
          ).and_return([diff_file])
        end

        send_request

        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end
end
