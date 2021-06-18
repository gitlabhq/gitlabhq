# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/operations/show' do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:error_tracking_setting) do
    create(:project_error_tracking_setting, project: project)
  end

  let_it_be_with_reload(:tracing_setting) do
    create(:project_tracing_setting, project: project)
  end

  let_it_be(:prometheus_integration) { create(:prometheus_integration, project: project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    assign :project, project

    allow(view).to receive(:error_tracking_setting)
      .and_return(error_tracking_setting)
    allow(view).to receive(:tracing_setting)
      .and_return(tracing_setting)
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

  describe 'Operations > Prometheus' do
    context 'when settings_operations_prometheus_service flag is enabled' do
      it 'renders the Operations Settings page' do
        render

        expect(rendered).to have_content _('Prometheus')
        expect(rendered).to have_content _('Link Prometheus monitoring to GitLab.')
        expect(rendered).to have_content _('To use a Prometheus installed on a cluster, deactivate the manual configuration.')
      end
    end

    context 'when settings_operations_prometheus_service is disabled' do
      before do
        stub_feature_flags(settings_operations_prometheus_service: false)
      end

      it 'renders the Operations Settings page' do
        render

        expect(rendered).not_to have_content _('Auto configuration settings are used unless you override their values here.')
      end
    end
  end

  describe 'Operations > Tracing' do
    context 'Settings page ' do
      it 'renders the Tracing Settings page' do
        render

        expect(rendered).to have_content _('Embed an image of your existing Jaeger server in GitLab.')
      end
    end
  end
end
