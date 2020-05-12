# frozen_string_literal: true

require 'spec_helper'

describe 'projects/services/_form' do
  let(:project) { create(:redmine_project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)

    allow(view).to receive_messages(current_user: user,
                                    can?: true,
                                    current_application_settings: Gitlab::CurrentSettings.current_application_settings)
  end

  context 'commit_events and merge_request_events' do
    before do
      assign(:service, project.redmine_service)
    end

    it 'display merge_request_events and commit_events descriptions' do
      allow(RedmineService).to receive(:supported_events).and_return(%w(commit merge_request))

      render

      expect(rendered).to have_content('Event will be triggered when a commit is created/updated')
      expect(rendered).to have_content('Event will be triggered when a merge request is created/updated/merged')
    end
  end
end
