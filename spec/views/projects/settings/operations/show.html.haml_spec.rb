# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/operations/show' do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let_it_be(:error_tracking_setting) do
    create(:project_error_tracking_setting, project: project)
  end

  let_it_be(:prometheus_integration) { create(:prometheus_integration, project: project) }

  before do
    assign :project, project

    allow(view).to receive(:error_tracking_setting)
      .and_return(error_tracking_setting)
    allow(view).to receive(:prometheus_integration)
      .and_return(prometheus_integration)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'Operations > Alerts' do
    it 'renders the Operations Settings page' do
      render

      expect(rendered).to have_content _('Alerts')
      expect(rendered).to have_content _('Display alerts from all configured monitoring tools.')
    end
  end

  describe 'Operations > Error Tracking' do
    context 'Settings page ' do
      it 'renders the Operations Settings page' do
        render

        expect(rendered).to have_content _('Error tracking')
        expect(rendered).to have_content _('Link Sentry to GitLab to discover and view the errors your application generates.')
      end
    end
  end
end
