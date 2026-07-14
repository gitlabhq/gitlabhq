# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::IntegrationHookLogsController, feature_category: :webhooks do
  let_it_be(:user) { create(:user) }
  let_it_be(:integration) { create(:datadog_integration) }
  let_it_be_with_refind(:web_hook) { integration.service_hook }
  let_it_be_with_refind(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }

  let(:project) { integration.project }

  it_behaves_like WebHooks::HookLogActions do
    let(:edit_hook_path) { edit_project_settings_integration_url(project, integration) }

    before do
      project.add_owner(user)
    end
  end
end
