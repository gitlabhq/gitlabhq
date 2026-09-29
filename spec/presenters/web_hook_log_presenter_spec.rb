# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHookLogPresenter, feature_category: :webhooks do
  include Gitlab::Routing.url_helpers

  describe '#details_path' do
    let(:web_hook_log) { build_stubbed(:web_hook_log, web_hook: web_hook) }
    let(:project) { build_stubbed(:project) }

    subject { web_hook_log.present.details_path }

    context 'project hook' do
      let(:web_hook) { build_stubbed(:project_hook, project: project) }

      it { is_expected.to eq(project_hook_hook_log_path(project, web_hook, web_hook_log)) }
    end

    context 'service hook' do
      let(:web_hook) { build_stubbed(:service_hook, integration: integration, project_id: project.id) }
      let(:integration) { build_stubbed(:drone_ci_integration, project: project) }

      it { is_expected.to eq(project_settings_integration_hook_log_path(project, integration, web_hook_log)) }
    end
  end

  describe '#retry_path' do
    let(:web_hook_log) { build_stubbed(:web_hook_log, web_hook: web_hook) }
    let(:project) { build_stubbed(:project) }

    subject { web_hook_log.present.retry_path }

    context 'project hook' do
      let(:web_hook) { build_stubbed(:project_hook, project: project) }

      it { is_expected.to eq(retry_project_hook_hook_log_path(project, web_hook, web_hook_log)) }
    end

    context 'service hook' do
      let(:web_hook) { build_stubbed(:service_hook, integration: integration, project_id: project.id) }
      let(:integration) { build_stubbed(:drone_ci_integration, project: project) }

      it { is_expected.to eq(retry_project_settings_integration_hook_log_path(project, integration, web_hook_log)) }
    end
  end
end
