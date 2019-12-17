# frozen_string_literal: true

require 'spec_helper'

describe WebHookLogPresenter do
  include Gitlab::Routing.url_helpers

  describe '#details_path' do
    let(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }
    let(:project) { create(:project) }

    subject { web_hook_log.present.details_path }

    context 'project hook' do
      let(:web_hook) { create(:project_hook, project: project) }

      it { is_expected.to eq(project_hook_hook_log_path(project, web_hook, web_hook_log)) }
    end

    context 'service hook' do
      let(:web_hook) { create(:service_hook, service: service) }
      let(:service) { create(:drone_ci_service, project: project) }

      it { is_expected.to eq(project_service_hook_log_path(project, service, web_hook_log)) }
    end
  end

  describe '#retry_path' do
    let(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }
    let(:project) { create(:project) }

    subject { web_hook_log.present.retry_path }

    context 'project hook' do
      let(:web_hook) { create(:project_hook, project: project) }

      it { is_expected.to eq(retry_project_hook_hook_log_path(project, web_hook, web_hook_log)) }
    end

    context 'service hook' do
      let(:web_hook) { create(:service_hook, service: service) }
      let(:service) { create(:drone_ci_service, project: project) }

      it { is_expected.to eq(retry_project_service_hook_log_path(project, service, web_hook_log)) }
    end
  end
end
