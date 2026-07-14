# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HookLogsController, :enable_admin_mode, feature_category: :webhooks do
  let_it_be(:user) { create(:admin) }
  let_it_be_with_refind(:web_hook) { create(:system_hook) }
  let_it_be_with_refind(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }

  it_behaves_like WebHooks::HookLogActions do
    let!(:show_path) { admin_hook_hook_log_path(web_hook, web_hook_log) }
    let!(:retry_path) { retry_admin_hook_hook_log_path(web_hook, web_hook_log) }
    let(:edit_hook_path) { edit_admin_hook_path(web_hook) }
  end
end
