# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceHookPresenter do
  let(:web_hook_log) { create(:web_hook_log, web_hook: service_hook) }
  let(:service_hook) { create(:service_hook, integration: integration) }
  let(:integration) { create(:drone_ci_integration, project: project) }
  let(:project) { create(:project) }

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
