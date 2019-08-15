require 'spec_helper'

describe API::Discussions do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :public, :repository, namespace: user.namespace) }
  let(:private_user) { create(:user) }

  before do
    project.add_developer(user)
  end

  context 'with cross-reference system notes', :request_store do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.project }
    let(:new_merge_request) { create(:merge_request) }
    let(:commit) { new_merge_request.project.commit }
    let!(:note) { create(:system_note, noteable: merge_request, project: project, note: cross_reference) }
    let!(:note_metadata) { create(:system_note_metadata, note: note, action: 'cross_reference') }
    let(:cross_reference) { "test commit #{commit.to_reference(project)}" }
    let(:pat) { create(:personal_access_token, user: user) }

    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/discussions" }

    before do
      project.add_developer(user)
      new_merge_request.project.add_developer(user)
    end

    it 'returns only the note that the user should see' do
      hidden_merge_request = create(:merge_request)
      new_cross_reference = "test commit #{hidden_merge_request.project.commit}"
      new_note = create(:system_note, noteable: merge_request, project: project, note: new_cross_reference)
      create(:system_note_metadata, note: new_note, action: 'cross_reference')

      get api(url, user, personal_access_token: pat)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response.count).to eq(1)
      expect(json_response.first['notes'].count).to eq(1)

      parsed_note = json_response.first['notes'].first
      expect(parsed_note['id']).to eq(note.id)
      expect(parsed_note['body']).to eq(cross_reference)
      expect(parsed_note['system']).to be true
    end

    it 'avoids Git calls and N+1 SQL queries' do
      expect_any_instance_of(Repository).not_to receive(:find_commit).with(commit.id)

      control = ActiveRecord::QueryRecorder.new do
        get api(url, user, personal_access_token: pat)
      end

      expect(response).to have_gitlab_http_status(200)

      RequestStore.clear!

      new_note = create(:system_note, noteable: merge_request, project: project, note: cross_reference)
      create(:system_note_metadata, note: new_note, action: 'cross_reference')

      RequestStore.clear!

      expect { get api(url, user, personal_access_token: pat) }.not_to exceed_query_limit(control)
      expect(response).to have_gitlab_http_status(200)
    end
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
    let!(:snippet_note) { create(:discussion_note_on_snippet, noteable: snippet, project: project, author: user) }

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
