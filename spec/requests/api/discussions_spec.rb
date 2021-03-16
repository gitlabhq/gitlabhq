# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Discussions do
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
