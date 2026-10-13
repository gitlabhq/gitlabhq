# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceHookPresenter, feature_category: :webhooks do
  let(:web_hook_log) { build_stubbed(:web_hook_log, web_hook: service_hook) }
  let(:integration) { build_stubbed(:drone_ci_integration, project: project) }
  let(:project) { build_stubbed(:project) }
  let(:service_hook) { build_stubbed(:service_hook, integration: integration, project_id: project.id) }

  describe '#logs_details_path' do
    subject { service_hook.present.logs_details_path(web_hook_log) }

    let(:expected_path) do
      "/#{project.full_path}/-/settings/integrations/#{integration.to_param}/hook_logs/#{web_hook_log.id}"
    end

    it { is_expected.to eq(expected_path) }
  end

  describe '#logs_retry_path' do
    subject { service_hook.present.logs_retry_path(web_hook_log) }

    let(:expected_path) do
      "/#{project.full_path}/-/settings/integrations/#{integration.to_param}/hook_logs/#{web_hook_log.id}/retry"
    end

    it { is_expected.to eq(expected_path) }
  end
end
