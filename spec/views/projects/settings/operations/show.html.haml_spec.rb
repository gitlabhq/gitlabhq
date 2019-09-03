# frozen_string_literal: true

require 'spec_helper'

describe 'projects/settings/operations/show' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    assign :project, project
  end

  describe 'Operations > Error Tracking' do
    before do
      project.add_reporter(user)

      allow(view).to receive(:error_tracking_setting)
        .and_return(error_tracking_setting)
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:incident_management_available?) { false }
    end

    let!(:error_tracking_setting) do
      create(:project_error_tracking_setting, project: project)
    end

    context 'Settings page ' do
      it 'renders the Operations Settings page' do
        render

        expect(rendered).to have_content _('Error Tracking')
        expect(rendered).to have_content _('To link Sentry to GitLab, enter your Sentry URL and Auth Token')
      end
    end
  end
end
