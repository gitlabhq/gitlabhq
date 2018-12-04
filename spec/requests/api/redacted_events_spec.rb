require 'spec_helper'

describe 'Redacted events in API::Events' do
  shared_examples 'private events are redacted' do
    it 'redacts events the user does not have access to' do
      expect_any_instance_of(Event).to receive(:visible_to_user?).and_call_original

      get api(path), user

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to contain_exactly(
        'project_id' => nil,
        'action_name' => nil,
        'target_id' => nil,
        'target_iid' => nil,
        'target_type' => nil,
        'author_id' => nil,
        'target_title' => 'Confidential event',
        'created_at' => nil,
        'author_username' => nil
      )
    end
  end

  describe '/users/:id/events' do
    let(:project) { create(:project, :public) }
    let(:path) { "/users/#{project.owner.id}/events" }
    let(:issue) { create(:issue, :confidential, project: project) }

    before do
      EventCreateService.new.open_issue(issue, issue.author)
    end

    context 'unauthenticated user views another user with private events' do
      let(:user) { nil }

      include_examples 'private events are redacted'
    end

    context 'authenticated user without access views another user with private events' do
      let(:user) { create(:user) }

      include_examples 'private events are redacted'
    end
  end

  describe '/projects/:id/events' do
    let(:project) { create(:project, :public) }
    let(:path) { "/projects/#{project.id}/events" }
    let(:issue) { create(:issue, :confidential, project: project) }

    before do
      EventCreateService.new.open_issue(issue, issue.author)
    end

    context 'unauthenticated user views public project' do
      let(:user) { nil }

      include_examples 'private events are redacted'
    end

    context 'authenticated user without access views public project' do
      let(:user) { create(:user) }

      include_examples 'private events are redacted'
    end
  end
end
