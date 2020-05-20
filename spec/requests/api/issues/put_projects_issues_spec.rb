# frozen_string_literal: true

require 'spec_helper'

describe API::Issues do
  let_it_be(:user) { create(:user) }
  let_it_be(:owner) { create(:owner) }
  let_it_be(:project, reload: true) do
    create(:project, :public, creator_id: owner.id, namespace: owner.namespace)
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

  describe 'PUT /projects/:id/issues/:issue_iid to update only title' do
    it 'updates a project issue' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: { title: 'updated title' }
      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['title']).to eq('updated title')
    end

    it 'returns 404 error if issue iid not found' do
      put api("/projects/#{project.id}/issues/44444", user),
        params: { title: 'updated title' }
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 error if issue id is used instead of the iid' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
        params: { title: 'updated title' }
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'allows special label names' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: {
          title: 'updated title',
          labels: 'label, label?, label&foo, ?, &'
        }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'allows special label names with labels param as array' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: {
          title: 'updated title',
          labels: ['label', 'label?', 'label&foo, ?, &']
        }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    context 'confidential issues' do
      it 'returns 403 for non project members' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", non_member),
          params: { title: 'updated title' }
        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 403 for project members with guest role' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", guest),
          params: { title: 'updated title' }
        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'updates a confidential issue for project members' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", user),
          params: { title: 'updated title' }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq('updated title')
      end

      it 'updates a confidential issue for author' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", author),
          params: { title: 'updated title' }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq('updated title')
      end

      it 'updates a confidential issue for admin' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", admin),
          params: { title: 'updated title' }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq('updated title')
      end

      it 'sets an issue to confidential' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          params: { confidential: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['confidential']).to be_truthy
      end

      it 'makes a confidential issue public' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", user),
          params: { confidential: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['confidential']).to be_falsy
      end

      it 'does not update a confidential issue with wrong confidential flag' do
        put api("/projects/#{project.id}/issues/#{confidential_issue.iid}", user),
          params: { confidential: 'foo' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('confidential is invalid')
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid with spam filtering' do
    include_context 'includes Spam constants'

    def update_issue
      put api("/projects/#{project.id}/issues/#{issue.iid}", user), params: params
    end

    let(:params) do
      {
        title: 'updated title',
        description: 'content here',
        labels: 'label, label2'
      }
    end

    before do
      expect_next_instance_of(Spam::SpamActionService) do |spam_service|
        expect(spam_service).to receive_messages(check_for_spam?: true)
      end

      expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
        expect(verdict_service).to receive(:execute).and_return(DISALLOW)
      end
    end

    context 'when allow_possible_spam feature flag is false' do
      before do
        stub_feature_flags(allow_possible_spam: false)
      end

      it 'does not update a project issue' do
        expect { update_issue }.not_to change { issue.reload.title }
      end

      it 'returns correct status and message' do
        update_issue

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to include('message' => { 'error' => 'Spam detected' })
      end

      it 'creates a new spam log entry' do
        expect { update_issue }
          .to log_spam(title: 'updated title', description: 'content here', user_id: user.id, noteable_type: 'Issue')
      end
    end

    context 'when allow_possible_spam feature flag is true' do
      it 'updates a project issue' do
        expect { update_issue }.to change { issue.reload.title }
      end

      it 'returns correct status and message' do
        update_issue

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'creates a new spam log entry' do
        expect { update_issue }
          .to log_spam(title: 'updated title', description: 'content here', user_id: user.id, noteable_type: 'Issue')
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update assignee' do
    context 'support for deprecated assignee_id' do
      it 'removes assignee' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          params: { assignee_id: 0 }

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['assignee']).to be_nil
      end

      it 'updates an issue with new assignee' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          params: { assignee_id: user2.id }

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['assignee']['name']).to eq(user2.name)
      end
    end

    it 'removes assignee' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: { assignee_ids: [0] }

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['assignees']).to be_empty
    end

    it 'updates an issue with new assignee' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: { assignee_ids: [user2.id] }

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['assignees'].first['name']).to eq(user2.name)
    end

    context 'single assignee restrictions' do
      it 'updates an issue with several assignees but only one has been applied' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          params: { assignee_ids: [user2.id, guest.id] }

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['assignees'].size).to eq(1)
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update labels' do
    let!(:label) { create(:label, title: 'dummy', project: project) }
    let!(:label_link) { create(:label_link, label: label, target: issue) }

    it 'does not update labels if not present' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: { title: 'updated title' }
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to eq([label.title])
    end

    it 'removes all labels and touches the record' do
      Timecop.travel(1.minute.from_now) do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user), params: { labels: '' }
      end

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to eq([])
      expect(json_response['updated_at']).to be > Time.now
    end

    it 'removes all labels and touches the record with labels param as array' do
      Timecop.travel(1.minute.from_now) do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user), params: { labels: [''] }
      end

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to eq([])
      expect(json_response['updated_at']).to be > Time.now
    end

    it 'updates labels and touches the record' do
      Timecop.travel(1.minute.from_now) do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          params: { labels: 'foo,bar' }
      end
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to include 'foo'
      expect(json_response['labels']).to include 'bar'
      expect(json_response['updated_at']).to be > Time.now
    end

    it 'updates labels and touches the record with labels param as array' do
      Timecop.travel(1.minute.from_now) do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
          params: { labels: %w(foo bar) }
      end
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to include 'foo'
      expect(json_response['labels']).to include 'bar'
      expect(json_response['updated_at']).to be > Time.now
    end

    it 'allows special label names' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: { labels: 'label:foo, label-bar,label_bar,label/bar,label?bar,label&bar,?,&' }
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to include 'label:foo'
      expect(json_response['labels']).to include 'label-bar'
      expect(json_response['labels']).to include 'label_bar'
      expect(json_response['labels']).to include 'label/bar'
      expect(json_response['labels']).to include 'label?bar'
      expect(json_response['labels']).to include 'label&bar'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'allows special label names with labels param as array' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: { labels: ['label:foo', 'label-bar', 'label_bar', 'label/bar,label?bar,label&bar,?,&'] }
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to include 'label:foo'
      expect(json_response['labels']).to include 'label-bar'
      expect(json_response['labels']).to include 'label_bar'
      expect(json_response['labels']).to include 'label/bar'
      expect(json_response['labels']).to include 'label?bar'
      expect(json_response['labels']).to include 'label&bar'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'returns 400 if title is too long' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: { title: 'g' * 256 }
      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['title']).to eq([
        'is too long (maximum is 255 characters)'
      ])
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update state and label' do
    it 'updates a project issue' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user),
        params: { labels: 'label2', state_event: 'close' }
      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['labels']).to include 'label2'
      expect(json_response['state']).to eq 'closed'
    end

    it 'reopens a project isssue' do
      put api("/projects/#{project.id}/issues/#{closed_issue.iid}", user), params: { state_event: 'reopen' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['state']).to eq 'opened'
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update updated_at param' do
    context 'when reporter makes request' do
      it 'accepts the update date to be set' do
        update_time = 2.weeks.ago

        put api("/projects/#{project.id}/issues/#{issue.iid}", user),
            params: { title: 'some new title', updated_at: update_time }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to include 'some new title'
        expect(Time.parse(json_response['updated_at'])).not_to be_like_time(update_time)
      end
    end

    context 'when admin or owner makes the request' do
      it 'not allow to set null for updated_at' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", owner), params: { updated_at: nil }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'not allow to set blank for updated_at' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", owner), params: { updated_at: '' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'not allow to set invalid format for updated_at' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", owner), params: { updated_at: 'invalid-format' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'accepts the update date to be set' do
        update_time = 2.weeks.ago
        put api("/projects/#{project.id}/issues/#{issue.iid}", owner),
            params: { title: 'some new title', updated_at: update_time }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to include 'some new title'

        expect(Time.parse(json_response['updated_at'])).to be_like_time(update_time)
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update due date' do
    it 'creates a new project issue' do
      due_date = 2.weeks.from_now.strftime('%Y-%m-%d')

      put api("/projects/#{project.id}/issues/#{issue.iid}", user), params: { due_date: due_date }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['due_date']).to eq(due_date)
    end
  end
end
