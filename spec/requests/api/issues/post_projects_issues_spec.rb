# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Issues do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) do
    create(:project, :public, creator_id: user.id, namespace: user.namespace)
  end

  let(:user2)             { create(:user) }
  let(:non_member)        { create(:user) }
  let_it_be(:guest)       { create(:user) }
  let_it_be(:author)      { create(:author) }
  let_it_be(:assignee)    { create(:assignee) }
  let(:admin)             { create(:user, :admin) }
  let(:issue_title)       { 'foo' }
  let(:issue_description) { 'closed' }
  let!(:closed_issue) do
    create :closed_issue,
      author: user,
      assignees: [user],
      project: project,
      state: :closed,
      milestone: milestone,
      created_at: generate(:past_time),
      updated_at: 3.hours.ago,
      closed_at: 1.hour.ago
  end

  let!(:confidential_issue) do
    create :issue,
      :confidential,
      project: project,
      author: author,
      assignees: [assignee],
      created_at: generate(:past_time),
      updated_at: 2.hours.ago
  end

  let!(:issue) do
    create :issue,
      author: user,
      assignees: [user],
      project: project,
      milestone: milestone,
      created_at: generate(:past_time),
      updated_at: 1.hour.ago,
      title: issue_title,
      description: issue_description
  end

  let_it_be(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end

  let!(:label_link) { create(:label_link, label: label, target: issue) }
  let(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  let_it_be(:empty_milestone) do
    create(:milestone, title: '2.0.0', project: project)
  end

  let!(:note) { create(:note_on_issue, author: user, project: project, noteable: issue) }

  let(:no_milestone_title) { 'None' }
  let(:any_milestone_title) { 'Any' }

  before_all do
    project.add_reporter(user)
    project.add_guest(guest)
  end

  before do
    stub_licensed_features(multiple_issue_assignees: false, issue_weights: false)
  end

  describe 'POST /projects/:id/issues' do
    context 'support for deprecated assignee_id' do
      it 'creates a new project issue' do
        post api("/projects/#{project.id}/issues", user),
          params: { title: 'new issue', assignee_id: user2.id }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['assignee']['name']).to eq(user2.name)
        expect(json_response['assignees'].first['name']).to eq(user2.name)
      end

      it 'creates a new project issue when assignee_id is empty' do
        post api("/projects/#{project.id}/issues", user),
          params: { title: 'new issue', assignee_id: '' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['assignee']).to be_nil
      end
    end

    context 'single assignee restrictions' do
      it 'creates a new project issue with no more than one assignee' do
        post api("/projects/#{project.id}/issues", user),
          params: { title: 'new issue', assignee_ids: [user2.id, guest.id] }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['assignees'].count).to eq(1)
      end
    end

    context 'user does not have permissions to create issue' do
      let(:not_member) { create(:user) }

      before do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
      end

      it 'renders 403' do
        post api("/projects/#{project.id}/issues", not_member), params: { title: 'new issue' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'an internal ID is provided' do
      context 'by an admin' do
        it 'sets the internal ID on the new issue' do
          post api("/projects/#{project.id}/issues", admin),
            params: { title: 'new issue', iid: 9001 }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['iid']).to eq 9001
        end
      end

      context 'by an owner' do
        it 'sets the internal ID on the new issue' do
          post api("/projects/#{project.id}/issues", user),
            params: { title: 'new issue', iid: 9001 }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['iid']).to eq 9001
        end
      end

      context 'by a group owner' do
        let(:group) { create(:group) }
        let(:group_project) { create(:project, :public, namespace: group) }

        it 'sets the internal ID on the new issue' do
          group.add_owner(user2)
          post api("/projects/#{group_project.id}/issues", user2),
            params: { title: 'new issue', iid: 9001 }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['iid']).to eq 9001
        end
      end

      context 'by another user' do
        it 'ignores the given internal ID' do
          post api("/projects/#{project.id}/issues", user2),
            params: { title: 'new issue', iid: 9001 }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['iid']).not_to eq 9001
        end
      end

      context 'when an issue with the same IID exists on database' do
        it 'returns 409' do
          post api("/projects/#{project.id}/issues", admin),
            params: { title: 'new issue', iid: issue.iid }

          expect(response).to have_gitlab_http_status(:conflict)
          expect(json_response['message']).to eq 'Duplicated issue'
        end
      end
    end

    it 'creates a new project issue' do
      post api("/projects/#{project.id}/issues", user),
        params: { title: 'new issue', labels: 'label, label2', weight: 3, assignee_ids: [user2.id] }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['description']).to be_nil
      expect(json_response['labels']).to eq(%w(label label2))
      expect(json_response['confidential']).to be_falsy
      expect(json_response['assignee']['name']).to eq(user2.name)
      expect(json_response['assignees'].first['name']).to eq(user2.name)
    end

    it 'creates a new project issue with labels param as array' do
      post api("/projects/#{project.id}/issues", user),
        params: { title: 'new issue', labels: %w(label label2), weight: 3, assignee_ids: [user2.id] }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['description']).to be_nil
      expect(json_response['labels']).to eq(%w(label label2))
      expect(json_response['confidential']).to be_falsy
      expect(json_response['assignee']['name']).to eq(user2.name)
      expect(json_response['assignees'].first['name']).to eq(user2.name)
    end

    it 'creates a new confidential project issue' do
      post api("/projects/#{project.id}/issues", user),
        params: { title: 'new issue', confidential: true }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_truthy
    end

    it 'creates a new confidential project issue with a different param' do
      post api("/projects/#{project.id}/issues", user),
        params: { title: 'new issue', confidential: 'y' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_truthy
    end

    it 'creates a public issue when confidential param is false' do
      post api("/projects/#{project.id}/issues", user),
        params: { title: 'new issue', confidential: false }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_falsy
    end

    it 'creates a public issue when confidential param is invalid' do
      post api("/projects/#{project.id}/issues", user),
        params: { title: 'new issue', confidential: 'foo' }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('confidential is invalid')
    end

    it 'returns a 400 bad request if title not given' do
      post api("/projects/#{project.id}/issues", user), params: { labels: 'label, label2' }
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'allows special label names' do
      post api("/projects/#{project.id}/issues", user),
        params: {
          title: 'new issue',
          labels: 'label, label?, label&foo, ?, &'
        }
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'allows special label names with labels param as array' do
      post api("/projects/#{project.id}/issues", user),
        params: {
          title: 'new issue',
          labels: ['label', 'label?', 'label&foo, ?, &']
        }
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'returns 400 if title is too long' do
      post api("/projects/#{project.id}/issues", user),
        params: { title: 'g' * 256 }
      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['title']).to eq([
        'is too long (maximum is 255 characters)'
      ])
    end

    context 'resolving discussions' do
      let(:discussion) { create(:diff_note_on_merge_request).to_discussion }
      let(:merge_request) { discussion.noteable }
      let(:project) { merge_request.source_project }

      before do
        project.add_maintainer(user)
      end

      context 'resolving all discussions in a merge request' do
        before do
          post api("/projects/#{project.id}/issues", user),
            params: {
              title: 'New Issue',
              merge_request_to_resolve_discussions_of: merge_request.iid
            }
        end

        it_behaves_like 'creating an issue resolving discussions through the API'
      end

      context 'resolving a single discussion' do
        before do
          post api("/projects/#{project.id}/issues", user),
            params: {
              title: 'New Issue',
              merge_request_to_resolve_discussions_of: merge_request.iid,
              discussion_to_resolve: discussion.id
            }
        end

        it_behaves_like 'creating an issue resolving discussions through the API'
      end
    end

    context 'with due date' do
      it 'creates a new project issue' do
        due_date = 2.weeks.from_now.strftime('%Y-%m-%d')

        post api("/projects/#{project.id}/issues", user),
          params: { title: 'new issue', due_date: due_date }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['description']).to be_nil
        expect(json_response['due_date']).to eq(due_date)
      end
    end

    context 'setting created_at' do
      let(:fixed_time) { Time.new(2001, 1, 1) }
      let(:creation_time) { 2.weeks.ago }
      let(:params) { { title: 'new issue', labels: 'label, label2', created_at: creation_time } }

      before do
        travel_to fixed_time
      end

      context 'by an admin' do
        it 'sets the creation time on the new issue' do
          post api("/projects/#{project.id}/issues", admin), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
          expect(ResourceLabelEvent.last.created_at).to be_like_time(creation_time)
        end
      end

      context 'by a project owner' do
        it 'sets the creation time on the new issue' do
          post api("/projects/#{project.id}/issues", user), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
          expect(ResourceLabelEvent.last.created_at).to be_like_time(creation_time)
        end
      end

      context 'by a group owner' do
        it 'sets the creation time on the new issue' do
          group = create(:group)
          group_project = create(:project, :public, namespace: group)
          group.add_owner(user2)

          post api("/projects/#{group_project.id}/issues", user2), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
          expect(ResourceLabelEvent.last.created_at).to be_like_time(creation_time)
        end
      end

      context 'by another user' do
        it 'ignores the given creation time' do
          project.add_developer(user2)

          post api("/projects/#{project.id}/issues", user2), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(Time.parse(json_response['created_at'])).to be_like_time(fixed_time)
          expect(ResourceLabelEvent.last.created_at).to be_like_time(fixed_time)
        end
      end
    end

    context 'the user can only read the issue' do
      it 'cannot create new labels' do
        expect do
          post api("/projects/#{project.id}/issues", non_member), params: { title: 'new issue', labels: 'label, label2' }
        end.not_to change { project.labels.count }
      end

      it 'cannot create new labels with labels param as array' do
        expect do
          post api("/projects/#{project.id}/issues", non_member), params: { title: 'new issue', labels: %w(label label2) }
        end.not_to change { project.labels.count }
      end
    end

    context 'when request exceeds the rate limit' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
      end

      it 'prevents users from creating more issues' do
        post api("/projects/#{project.id}/issues", user),
        params: { title: 'new issue', labels: 'label, label2', weight: 3, assignee_ids: [user2.id] }

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
      end
    end
  end

  describe 'POST /projects/:id/issues with spam filtering' do
    def post_issue
      post api("/projects/#{project.id}/issues", user), params: params
    end

    before do
      expect_next_instance_of(Spam::SpamActionService) do |spam_service|
        expect(spam_service).to receive_messages(check_for_spam?: true)
      end
      expect_next_instance_of(Spam::AkismetService) do |akismet_service|
        expect(akismet_service).to receive_messages(spam?: true)
      end
    end

    let(:params) do
      {
        title: 'new issue',
        description: 'content here',
        labels: 'label, label2'
      }
    end

    context 'when allow_possible_spam feature flag is false' do
      before do
        stub_feature_flags(allow_possible_spam: false)
      end

      it 'does not create a new project issue' do
        expect { post_issue }.not_to change(Issue, :count)
      end

      it 'returns correct status and message' do
        post_issue

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq({ 'error' => 'Spam detected' })
      end

      it 'creates a new spam log entry' do
        expect { post_issue }
          .to log_spam(title: 'new issue', description: 'content here', user_id: user.id, noteable_type: 'Issue')
      end
    end

    context 'when allow_possible_spam feature flag is true' do
      it 'does creates a new project issue' do
        expect { post_issue }.to change(Issue, :count).by(1)
      end

      it 'returns correct status' do
        post_issue

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'creates a new spam log entry' do
        expect { post_issue }
          .to log_spam(title: 'new issue', description: 'content here', user_id: user.id, noteable_type: 'Issue')
      end
    end
  end

  describe '/projects/:id/issues/:issue_iid/move' do
    let!(:target_project) { create(:project, creator_id: user.id, namespace: user.namespace ) }
    let!(:target_project2) { create(:project, creator_id: non_member.id, namespace: non_member.namespace ) }

    it 'moves an issue' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/move", user),
        params: { to_project_id: target_project.id }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['project_id']).to eq(target_project.id)
    end

    context 'when source and target projects are the same' do
      it 'returns 400 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/#{issue.iid}/move", user),
          params: { to_project_id: project.id }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(s_('MoveIssue|Cannot move issue to project it originates from!'))
      end
    end

    context 'when the user does not have the permission to move issues' do
      it 'returns 400 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/#{issue.iid}/move", user),
          params: { to_project_id: target_project2.id }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(s_('MoveIssue|Cannot move issue due to insufficient permissions!'))
      end
    end

    it 'moves the issue to another namespace if I am admin' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/move", admin),
        params: { to_project_id: target_project2.id }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['project_id']).to eq(target_project2.id)
    end

    context 'when using the issue ID instead of iid' do
      it 'returns 404 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/#{issue.id}/move", user),
          params: { to_project_id: target_project.id }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Issue Not Found')
      end
    end

    context 'when issue does not exist' do
      it 'returns 404 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/123/move", user),
          params: { to_project_id: target_project.id }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Issue Not Found')
      end
    end

    context 'when source project does not exist' do
      it 'returns 404 when trying to move an issue' do
        post api("/projects/0/issues/#{issue.iid}/move", user),
          params: { to_project_id: target_project.id }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end
    end

    context 'when target project does not exist' do
      it 'returns 404 when trying to move an issue' do
        post api("/projects/#{project.id}/issues/#{issue.iid}/move", user),
          params: { to_project_id: 0 }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST :id/issues/:issue_iid/subscribe' do
    it 'subscribes to an issue' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/subscribe", user2)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['subscribed']).to eq(true)
    end

    it 'returns 304 if already subscribed' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/subscribe", user)

      expect(response).to have_gitlab_http_status(:not_modified)
    end

    it 'returns 404 if the issue is not found' do
      post api("/projects/#{project.id}/issues/123/subscribe", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 if the issue ID is used instead of the iid' do
      post api("/projects/#{project.id}/issues/#{issue.id}/subscribe", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 if the issue is confidential' do
      post api("/projects/#{project.id}/issues/#{confidential_issue.iid}/subscribe", non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'POST :id/issues/:issue_id/unsubscribe' do
    it 'unsubscribes from an issue' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/unsubscribe", user)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['subscribed']).to eq(false)
    end

    it 'returns 304 if not subscribed' do
      post api("/projects/#{project.id}/issues/#{issue.iid}/unsubscribe", user2)

      expect(response).to have_gitlab_http_status(:not_modified)
    end

    it 'returns 404 if the issue is not found' do
      post api("/projects/#{project.id}/issues/123/unsubscribe", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 if using the issue ID instead of iid' do
      post api("/projects/#{project.id}/issues/#{issue.id}/unsubscribe", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 if the issue is confidential' do
      post api("/projects/#{project.id}/issues/#{confidential_issue.iid}/unsubscribe", non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
