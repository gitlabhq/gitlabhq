# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Discussions, feature_category: :team_planning do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :public, :repository, namespace: user.namespace) }
  let(:private_user) { create(:user) }

  before do
    project.add_developer(user)
  end

  context 'when discussions have cross-reference system notes' do
    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/discussions" }
    let(:notes_in_response) { json_response.first['notes'] }

    it_behaves_like 'with cross-reference system notes'
  end

  context 'when noteable is an Issue' do
    let!(:issue) { create(:issue, project: project, author: user) }
    let!(:issue_note) { create(:discussion_note_on_issue, noteable: issue, project: project, author: user) }

    it_behaves_like 'discussions API', 'projects', 'issues', 'iid', can_reply_to_individual_notes: true do
      let(:parent) { project }
      let(:noteable) { issue }
      let(:note) { issue_note }
    end
  end

  context 'when noteable is a WorkItem' do
    let!(:work_item) { create(:work_item, project: project, author: user) }
    let!(:work_item_note) { create(:discussion_note_on_issue, noteable: work_item, project: project, author: user) }

    let(:parent) { project }
    let(:noteable) { work_item }
    let(:note) { work_item_note }
    let(:url) { "/projects/#{parent.id}/issues/#{noteable[:iid]}/discussions" }

    it_behaves_like 'discussions API', 'projects', 'issues', 'iid', can_reply_to_individual_notes: true

    context 'with work item without notes widget' do
      before do
        WorkItems::Type.default_by_type(:issue).widget_definitions.find_by_widget_type(:notes).update!(disabled: true)
      end

      context 'when fetching discussions' do
        it "returns 404" do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when single fetching discussion by discussion_id' do
        it "returns 404" do
          get api("#{url}/#{work_item_note.discussion_id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when trying to create a new discussion' do
        it "returns 404" do
          post api(url, user), params: { body: 'hi!' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when trying to create a new comment on a discussion' do
        it 'returns 404' do
          post api("#{url}/#{note.discussion_id}/notes", user), params: { body: 'Hello!' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when trying to update a new comment on a discussion' do
        it 'returns 404' do
          put api("#{url}/notes/#{note.id}", user), params: { body: 'Update Hello!' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when deleting a note' do
        it 'returns 404' do
          delete api("#{url}/#{note.discussion_id}/notes/#{note.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  context 'when noteable is a Snippet' do
    let!(:snippet) { create(:project_snippet, project: project, author: user) }
    let!(:snippet_note) { create(:discussion_note_on_project_snippet, noteable: snippet, project: project, author: user) }

    it_behaves_like 'discussions API', 'projects', 'snippets', 'id' do
      let(:parent) { project }
      let(:noteable) { snippet }
      let(:note) { snippet_note }
    end
  end

  context 'when noteable is a Merge Request' do
    let!(:noteable) { create(:merge_request_with_diffs, source_project: project, target_project: project, author: user) }
    let!(:note) { create(:discussion_note_on_merge_request, noteable: noteable, project: project, author: user) }
    let!(:diff_note) { create(:diff_note_on_merge_request, noteable: noteable, project: project, author: user) }
    let(:parent) { project }

    it_behaves_like 'discussions API', 'projects', 'merge_requests', 'iid', can_reply_to_individual_notes: true
    it_behaves_like 'diff discussions API', 'projects', 'merge_requests', 'iid'
    it_behaves_like 'resolvable discussions API', 'projects', 'merge_requests', 'iid'

    context "when position_type is file" do
      it "creates a new diff note" do
        position = diff_note.position.to_h.merge({ position_type: 'file' }).except(:ignore_whitespace_change)

        post api("/projects/#{parent.id}/merge_requests/#{noteable['iid']}/discussions", user),
          params: { body: 'hi!', position: position }

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context "when position is for a previous commit on the merge request" do
      it "returns a 400 bad request error because the line_code is old" do
        # SHA taken from an earlier commit listed in spec/factories/merge_requests.rb
        position = diff_note.position.to_h.merge(new_line: 'c1acaa58bbcbc3eafe538cb8274ba387047b69f8')

        post api("/projects/#{project.id}/merge_requests/#{noteable['iid']}/discussions", user),
          params: { body: 'hi!', position: position }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context "when a commit parameter is given" do
      it "creates the discussion on that commit within the merge request" do
        # SHAs of "feature" and its parent in spec/support/gitlab-git-test.git
        mr_commit = '0b4bc9a49b562e85de7cc9e834518ea6828729b9'
        parent_commit = 'ae73cb07c9eeaf35924a10f713b364d32b2dd34f'
        file = "files/ruby/feature.rb"
        position = build(
          :text_diff_position,
          :added,
          file: file,
          new_line: 1,
          base_sha: parent_commit,
          head_sha: mr_commit,
          start_sha: parent_commit
        )

        post api("/projects/#{project.id}/merge_requests/#{noteable['iid']}/discussions", user),
          params: { body: 'MR discussion on commit', position: position.to_h, commit_id: mr_commit }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['notes'].first['commit_id']).to eq(mr_commit)
      end
    end
  end

  context 'when noteable is a Commit' do
    let!(:noteable) { create(:commit, project: project, author: user) }
    let!(:note) { create(:discussion_note_on_commit, commit_id: noteable.id, project: project, author: user) }
    let!(:diff_note) { create(:diff_note_on_commit, commit_id: noteable.id, project: project, author: user) }
    let(:parent) { project }

    it_behaves_like 'discussions API', 'projects', 'repository/commits', 'id'
    it_behaves_like 'diff discussions API', 'projects', 'repository/commits', 'id'
  end
end
