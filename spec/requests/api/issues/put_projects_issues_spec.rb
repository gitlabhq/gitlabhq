# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Issues, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:owner) { create(:owner) }
  let(:user2)             { create(:user) }
  let(:non_member)        { create(:user) }
  let_it_be(:guest)       { create(:user) }
  let_it_be(:author)      { create(:author) }
  let_it_be(:assignee)    { create(:assignee) }
  let(:admin)             { create(:user, :admin) }
  let(:issue_title)       { 'foo' }
  let(:issue_description) { 'closed' }

  let_it_be(:project, reload: true) do
    create(:project, :public, creator_id: owner.id, namespace: owner.namespace, reporters: user, guests: guest)
  end

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
  let(:updated_title) { 'updated title' }
  let(:issue_path) { "/projects/#{project.id}/issues/#{issue.iid}" }
  let(:api_for_user) { api(issue_path, user) }

  before do
    stub_licensed_features(multiple_issue_assignees: false, issue_weights: false)
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update only title' do
    it_behaves_like 'PUT request permissions for admin mode' do
      let(:path) { "/projects/#{project.id}/issues/#{confidential_issue.iid}" }
      let(:params) { { title: updated_title } }
    end

    it 'updates a project issue', :aggregate_failures do
      put api_for_user, params: { title: updated_title }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['title']).to eq(updated_title)
    end

    it 'returns 404 error if issue iid not found' do
      put api("/projects/#{project.id}/issues/#{non_existing_record_id}", user), params: { title: updated_title }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 error if issue id is used instead of the iid' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user), params: { title: updated_title }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'allows special label names' do
      put api_for_user,
        params: {
          title: updated_title,
          labels: 'label, label?, label&foo, ?, &'
        }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'allows special label names with labels param as array', :aggregate_failures do
      put api_for_user,
        params: {
          title: updated_title,
          labels: ['label', 'label?', 'label&foo, ?, &']
        }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to contain_exactly('label', 'label?', 'label&foo', '?', '&')
    end

    context 'confidential issues' do
      let(:confidential_issue_path) { "/projects/#{project.id}/issues/#{confidential_issue.iid}" }

      it 'returns 403 for non project members' do
        put api(confidential_issue_path, non_member), params: { title: updated_title }

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 403 for project members with guest role' do
        put api(confidential_issue_path, guest), params: { title: updated_title }

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'updates a confidential issue for project members', :aggregate_failures do
        put api(confidential_issue_path, user), params: { title: updated_title }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq(updated_title)
      end

      it 'updates a confidential issue for author', :aggregate_failures do
        put api(confidential_issue_path, author), params: { title: updated_title }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq(updated_title)
      end

      it 'updates a confidential issue for admin', :aggregate_failures do
        put api(confidential_issue_path, admin, admin_mode: true), params: { title: updated_title }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq(updated_title)
      end

      it 'sets an issue to confidential', :aggregate_failures do
        put api_for_user, params: { confidential: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['confidential']).to be_truthy
      end

      it 'makes a confidential issue public', :aggregate_failures do
        put api(confidential_issue_path, user), params: { confidential: false }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['confidential']).to be_falsy
      end

      it 'does not update a confidential issue with wrong confidential flag', :aggregate_failures do
        put api(confidential_issue_path, user), params: { confidential: 'foo' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('confidential is invalid')
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid with spam filtering' do
    include_context 'includes Spam constants'

    def update_issue
      put api_for_user, params: params
    end

    let(:params) do
      {
        title: updated_title,
        description: 'content here',
        labels: 'label, label2'
      }
    end

    before do
      expect_next_instance_of(Spam::SpamActionService) do |spam_service|
        expect(spam_service).to receive_messages(check_for_spam?: true)
      end

      allow_next_instance_of(Spam::AkismetService) do |akismet_service|
        allow(akismet_service).to receive(:spam?).and_return(true)
      end
    end

    context 'when allow_possible_spam application setting is false' do
      it 'does not update a project issue' do
        expect { update_issue }.not_to change { issue.reload.title }
      end

      it 'returns correct status and message', :aggregate_failures do
        update_issue

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['base']).to match_array([/issue has been recognized as spam/])
      end

      it 'creates a new spam log entry' do
        expect { update_issue }
          .to log_spam(title: updated_title, description: 'content here', user_id: user.id, noteable_type: 'Issue')
      end
    end

    context 'when allow_possible_spam application setting is true' do
      before do
        stub_application_setting(allow_possible_spam: true)
      end

      it 'updates a project issue' do
        expect { update_issue }.to change { issue.reload.title }
      end

      it 'returns correct status and message' do
        update_issue

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'creates a new spam log entry' do
        expect { update_issue }
          .to log_spam(title: updated_title, description: 'content here', user_id: user.id, noteable_type: 'Issue')
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update assignee' do
    context 'support for deprecated assignee_id' do
      it 'removes assignee', :aggregate_failures do
        put api_for_user, params: { assignee_id: 0 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['assignee']).to be_nil
      end

      it 'updates an issue with new assignee', :aggregate_failures do
        put api_for_user, params: { assignee_id: user2.id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['assignee']['name']).to eq(user2.name)
      end
    end

    it 'removes assignee', :aggregate_failures do
      put api_for_user, params: { assignee_ids: [0] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['assignees']).to be_empty
    end

    it 'updates an issue with new assignee', :aggregate_failures do
      put api_for_user, params: { assignee_ids: [user2.id] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['assignees'].first['name']).to eq(user2.name)
    end

    context 'single assignee restrictions', :aggregate_failures do
      it 'updates an issue with several assignees but only one has been applied' do
        put api_for_user, params: { assignee_ids: [user2.id, guest.id] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['assignees'].size).to eq(1)
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update labels' do
    let!(:label) { create(:label, title: 'dummy', project: project) }
    let!(:label_link) { create(:label_link, label: label, target: issue) }

    it 'adds relevant labels', :aggregate_failures do
      put api_for_user, params: { add_labels: '1, 2' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to contain_exactly(label.title, '1', '2')
    end

    context 'removes' do
      let!(:label2) { create(:label, title: 'a-label', project: project) }
      let!(:label_link2) { create(:label_link, label: label2, target: issue) }

      it 'removes relevant labels', :aggregate_failures do
        put api_for_user, params: { remove_labels: label2.title }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['labels']).to eq([label.title])
      end

      it 'removes all labels', :aggregate_failures do
        put api_for_user, params: { remove_labels: "#{label.title}, #{label2.title}" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['labels']).to be_empty
      end
    end

    it 'does not update labels if not present', :aggregate_failures do
      put api_for_user, params: { title: updated_title }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to eq([label.title])
    end

    it 'removes all labels and touches the record', :aggregate_failures do
      travel_to(2.minutes.from_now) do
        put api_for_user, params: { labels: '' }
      end

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to eq([])
      expect(Time.parse(json_response['updated_at'])).to be_future
    end

    it 'removes all labels and touches the record with labels param as array', :aggregate_failures do
      travel_to(2.minutes.from_now) do
        put api_for_user, params: { labels: [''] }
      end

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to eq([])
      expect(Time.parse(json_response['updated_at'])).to be_future
    end

    it 'updates labels and touches the record', :aggregate_failures do
      travel_to(2.minutes.from_now) do
        put api_for_user, params: { labels: 'foo,bar' }
      end

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to contain_exactly('foo', 'bar')
      expect(Time.parse(json_response['updated_at'])).to be_future
    end

    it 'updates labels and touches the record with labels param as array', :aggregate_failures do
      travel_to(2.minutes.from_now) do
        put api_for_user, params: { labels: %w[foo bar] }
      end

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to include 'foo'
      expect(json_response['labels']).to include 'bar'
      expect(Time.parse(json_response['updated_at'])).to be_future
    end

    it 'allows special label names', :aggregate_failures do
      put api_for_user, params: { labels: 'label:foo, label-bar,label_bar,label/bar,label?bar,label&bar,?,&' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to contain_exactly('label:foo', 'label-bar', 'label_bar', 'label/bar', 'label?bar', 'label&bar', '?', '&')
    end

    it 'allows special label names with labels param as array', :aggregate_failures do
      put api_for_user, params: { labels: ['label:foo', 'label-bar', 'label_bar', 'label/bar,label?bar,label&bar,?,&'] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to contain_exactly('label:foo', 'label-bar', 'label_bar', 'label/bar', 'label?bar', 'label&bar', '?', '&')
    end

    it 'returns 400 if title is too long', :aggregate_failures do
      put api_for_user, params: { title: 'g' * 256 }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['title']).to eq(['is too long (maximum is 255 characters)'])
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update state and label' do
    it 'updates a project issue', :aggregate_failures do
      put api_for_user, params: { labels: 'label2', state_event: 'close' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['labels']).to contain_exactly('label2')
      expect(json_response['state']).to eq 'closed'
    end

    it 'reopens a project isssue', :aggregate_failures do
      put api(issue_path, user), params: { state_event: 'reopen' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['state']).to eq 'opened'
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update updated_at param' do
    context 'when reporter makes request' do
      it 'accepts the update date to be set', :aggregate_failures do
        update_time = 2.weeks.ago

        put api_for_user, params: { title: 'some new title', updated_at: update_time }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq('some new title')
        expect(Time.parse(json_response['updated_at'])).not_to be_like_time(update_time)
      end
    end

    context 'when admin or owner makes the request' do
      let(:api_for_owner) { api(issue_path, owner) }

      it 'not allow to set null for updated_at' do
        put api_for_owner, params: { updated_at: nil }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'not allow to set blank for updated_at' do
        put api_for_owner, params: { updated_at: '' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'not allow to set invalid format for updated_at' do
        put api_for_owner, params: { updated_at: 'invalid-format' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'accepts the update date to be set', :aggregate_failures do
        update_time = 2.weeks.ago
        put api_for_owner, params: { title: 'some new title', updated_at: update_time }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq('some new title')
        expect(Time.parse(json_response['updated_at'])).to be_like_time(update_time)
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_iid to update due date' do
    it 'creates a new project issue', :aggregate_failures do
      due_date = 2.weeks.from_now.to_date.iso8601

      put api_for_user, params: { due_date: due_date }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['due_date']).to eq(due_date)
    end
  end
end
