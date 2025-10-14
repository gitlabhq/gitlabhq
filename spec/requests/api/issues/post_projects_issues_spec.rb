# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Issues, :aggregate_failures, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) do
    create(:project, :public, creator_id: user.id, namespace: user.namespace, reporters: user)
  end

  let_it_be(:user2) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:author) { create(:author) }
  let_it_be(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  let_it_be(:assignee) { create(:assignee) }
  let_it_be(:admin) { create(:user, :admin) }

  let_it_be(:closed_issue) do
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

  let_it_be(:confidential_issue) do
    create :issue,
      :confidential,
      project: project,
      author: author,
      assignees: [assignee],
      created_at: generate(:past_time),
      updated_at: 2.hours.ago
  end

  let_it_be(:issue) do
    create :issue,
      author: user,
      assignees: [user],
      project: project,
      milestone: milestone,
      created_at: generate(:past_time),
      updated_at: 1.hour.ago,
      title: 'foo',
      description: 'closed'
  end

  let_it_be(:note) { create(:note_on_issue, author: user, project: project, noteable: issue) }

  let_it_be(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end

  let!(:label_link) { create(:label_link, label: label, target: issue) }
  let_it_be(:empty_milestone) do
    create(:milestone, title: '2.0.0', project: project)
  end

  let(:no_milestone_title) { 'None' }
  let(:any_milestone_title) { 'Any' }

  before do
    stub_licensed_features(multiple_issue_assignees: false, issue_weights: false)
  end

  describe 'POST /projects/:id/issues' do
    it_behaves_like 'authorizing granular token permissions', :create_issue do
      let(:boundary_object) { project }
      let(:request) do
        post api("/projects/#{project.id}/issues", personal_access_token: pat),
          params: { title: 'new issue', assignee_id: user2.id }
      end
    end

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
          post api("/projects/#{project.id}/issues", admin, admin_mode: true),
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
          post api("/projects/#{project.id}/issues", admin, admin_mode: true),
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
      expect(json_response['labels']).to eq(%w[label label2])
      expect(json_response['confidential']).to be_falsy
      expect(json_response['assignee']['name']).to eq(user2.name)
      expect(json_response['assignees'].first['name']).to eq(user2.name)
    end

    it 'creates a new project issue with labels param as array' do
      post api("/projects/#{project.id}/issues", user),
        params: { title: 'new issue', labels: %w[label label2], weight: 3, assignee_ids: [user2.id] }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['description']).to be_nil
      expect(json_response['labels']).to eq(%w[label label2])
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
      expect(json_response['message']['title']).to eq(['is too long (maximum is 255 characters)'])
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
              title: 'New issue',
              merge_request_to_resolve_discussions_of: merge_request.iid
            }
        end

        it_behaves_like 'creating an issue resolving discussions through the API'
      end

      context 'resolving a single discussion' do
        before do
          post api("/projects/#{project.id}/issues", user),
            params: {
              title: 'New issue',
              merge_request_to_resolve_discussions_of: merge_request.iid,
              discussion_to_resolve: discussion.id
            }
        end

        it_behaves_like 'creating an issue resolving discussions through the API'
      end
    end

    context 'with due date' do
      it 'creates a new project issue' do
        due_date = 2.weeks.from_now.to_date.iso8601

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
          post api("/projects/#{project.id}/issues", admin, admin_mode: true), params: params

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
          post api("/projects/#{project.id}/issues", non_member), params: { title: 'new issue', labels: %w[label label2] }
        end.not_to change { project.labels.count }
      end
    end

    context 'when request exceeds the rate limit' do
      it 'prevents users from creating more issues' do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

        post api("/projects/#{project.id}/issues", user),
          params: { title: 'new issue', labels: 'label, label2', weight: 3, assignee_ids: [user2.id] }

        expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  describe 'POST /projects/:id/issues with spam filtering' do
    def post_issue
      post api("/projects/#{project.id}/issues", user), params: params
    end

    before do
      expect_next_instance_of(Issue) do |instance|
        expect(instance).to receive(:check_for_spam).with(user: user, action: :create).and_call_original
      end

      expect_next_instance_of(Spam::AkismetService) do |akismet_service|
        expect(akismet_service).to receive(:spam?).and_return(true)
      end
    end

    let(:params) do
      {
        title: 'new issue',
        description: 'content here',
        labels: 'label, label2'
      }
    end

    context 'when allow_possible_spam application setting is false' do
      it 'does not create a new project issue' do
        expect { post_issue }.not_to change(Issue, :count)
      end

      it 'returns correct status and message' do
        post_issue

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['base']).to match_array([/issue has been recognized as spam/])
      end

      it 'creates a new spam log entry' do
        expect { post_issue }
          .to log_spam(title: 'new issue', description: 'content here', user_id: user.id, noteable_type: 'Issue')
      end
    end

    context 'when allow_possible_spam application setting is true' do
      before do
        stub_application_setting(allow_possible_spam: true)
      end

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
    shared_examples 'move work item api requests' do
      let_it_be(:target_project) { create(:project, creator_id: user.id, namespace: user.namespace) }
      let_it_be(:target_project2) { create(:project, creator_id: non_member.id, namespace: non_member.namespace) }
      let(:path) { "/projects/#{project.id}/issues/#{issue.iid}/move" }

      it_behaves_like 'POST request permissions for admin mode' do
        let(:params) { { to_project_id: target_project2.id } }
        let(:failed_status_code) { 400 }
      end

      it 'moves an issue' do
        post api(path, user), params: { to_project_id: target_project.id }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['project_id']).to eq(target_project.id)
      end

      context 'when source and target projects are the same' do
        it 'returns 400 when trying to move an issue' do
          post api(path, user), params: { to_project_id: project.id }

          expect(json_response['id']).to eq(issue.id)
        end
      end

      context 'when the user does not have the permission to move issues' do
        it 'returns 400 when trying to move an issue' do
          post api(path, user),
            params: { to_project_id: target_project2.id }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("Unable to move. You have insufficient permissions.")
        end
      end

      it 'moves the issue to another namespace if I am admin' do
        post api(path, admin, admin_mode: true),
          params: { to_project_id: target_project2.id }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['project_id']).to eq(target_project2.id)
      end

      context 'when using the issue ID instead of iid' do
        it 'returns 404 when trying to move an issue', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/341520' do
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
          post api(path, user),
            params: { to_project_id: 0 }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    it_behaves_like 'move work item api requests'
  end

  describe '/projects/:id/issues/:issue_iid/clone' do
    shared_examples 'clone work item api requests' do
      let_it_be(:valid_target_project) { create(:project) }
      let_it_be(:invalid_target_project) { create(:project) }

      before_all do
        valid_target_project.add_maintainer(user)
      end

      context 'when user can admin the issue' do
        shared_examples 'clones the issue' do
          it 'clones the issue' do
            expect do
              post_clone_issue(user, issue, target_project)
            end.to change { target_project.issues.count }.by(1)

            cloned_issue = Issue.last

            expect(cloned_issue.notes.count).to eq(1)
            expect(cloned_issue.notes.pluck(:note)).not_to include(issue.notes.first.note)
            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['id']).to eq(cloned_issue.id)
            expect(json_response['project_id']).to eq(target_project.id)
          end
        end

        context 'when the user can admin the target project' do
          it_behaves_like 'clones the issue' do
            let(:target_project) { valid_target_project }
          end

          context 'when target project is the same source project' do
            it_behaves_like 'clones the issue' do
              let(:target_project) { issue.project }
            end
          end
        end
      end

      context 'when the user does not have the permission to clone issues' do
        it 'returns 400' do
          post api("/projects/#{project.id}/issues/#{issue.iid}/clone", user),
            params: { to_project_id: invalid_target_project.id }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("Unable to clone. You have insufficient permissions.")
        end
      end

      context 'when using the issue ID instead of iid' do
        it 'returns 404', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/341520' do
          post api("/projects/#{project.id}/issues/#{issue.id}/clone", user),
            params: { to_project_id: valid_target_project.id }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Issue Not Found')
        end
      end

      context 'when issue does not exist' do
        it 'returns 404' do
          post api("/projects/#{project.id}/issues/12300/clone", user),
            params: { to_project_id: valid_target_project.id }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Issue Not Found')
        end
      end

      context 'when source project does not exist' do
        it 'returns 404' do
          post api("/projects/0/issues/#{issue.iid}/clone", user),
            params: { to_project_id: valid_target_project.id }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'when target project does not exist' do
        it 'returns 404' do
          post api("/projects/#{project.id}/issues/#{issue.iid}/clone", user),
            params: { to_project_id: 0 }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      it 'clones the issue with notes when with_notes is true' do
        expect do
          post api("/projects/#{project.id}/issues/#{issue.iid}/clone", user),
            params: { to_project_id: valid_target_project.id, with_notes: true }
        end.to change { valid_target_project.issues.count }.by(1)

        cloned_issue = Issue.last

        expect(cloned_issue.notes.count).to eq(issue.notes.count)
        expect(cloned_issue.notes.pluck(:note)).to include(issue.notes.first.note)
        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['id']).to eq(cloned_issue.id)
        expect(json_response['project_id']).to eq(valid_target_project.id)
      end
    end

    it_behaves_like 'clone work item api requests'
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

    it 'returns 404 if the issue ID is used instead of the iid', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/341520' do
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

    it 'returns 404 if using the issue ID instead of iid', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/341520' do
      post api("/projects/#{project.id}/issues/#{issue.id}/unsubscribe", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 if the issue is confidential' do
      post api("/projects/#{project.id}/issues/#{confidential_issue.iid}/unsubscribe", non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  def post_clone_issue(current_user, issue, target_project)
    post api("/projects/#{issue.project.id}/issues/#{issue.iid}/clone", current_user),
      params: { to_project_id: target_project.id }
  end
end
