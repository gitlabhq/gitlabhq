# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HookLogsController, feature_category: :webhooks do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:web_hook) { create(:project_hook) }
  let_it_be_with_refind(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }

  let(:project) { web_hook.project }

  it_behaves_like WebHooks::HookLogActions do
    let(:edit_hook_path) { edit_project_hook_url(project, web_hook) }

    before do
      project.add_owner(user)
    end
  end
end
