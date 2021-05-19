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

  let_it_be(:prometheus_service) { create(:prometheus_service, project: project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    assign :project, project

    allow(view).to receive(:error_tracking_setting)
      .and_return(error_tracking_setting)
    allow(view).to receive(:tracing_setting)
      .and_return(tracing_setting)
    allow(view).to receive(:prometheus_service)
      .and_return(prometheus_service)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'Operations > Alerts' do
    it 'renders the Operations Settings page' do
      render

      expect(rendered).to have_content _('Alert integrations')
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
        expect(rendered).to have_content _('To enable the installation of Prometheus on your clusters, deactivate the manual configuration.')
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
    context 'with project.tracing_external_url' do
      it 'links to project.tracing_external_url' do
        render

        expect(rendered).to have_link('Tracing', href: tracing_setting.external_url)
      end

      context 'with malicious external_url' do
        let(:malicious_tracing_url) { "https://replaceme.com/'><script>alert(document.cookie)</script>" }
        let(:cleaned_url) { "https://replaceme.com/'>" }

        before do
          tracing_setting.update_column(:external_url, malicious_tracing_url)
        end

        it 'sanitizes external_url' do
          render

          expect(tracing_setting.external_url).to eq(malicious_tracing_url)
          expect(rendered).to have_link('Tracing', href: cleaned_url)
        end
      end
    end

    context 'without project.tracing_external_url' do
      let(:tracing_setting) { build(:project_tracing_setting, project: project) }

      before do
        tracing_setting.external_url = nil
      end

      it 'links to Tracing page' do
        render

        expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
      end
    end
  end
end
