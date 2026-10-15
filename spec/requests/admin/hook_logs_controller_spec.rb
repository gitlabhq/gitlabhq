# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HookLogsController, :enable_admin_mode, :with_current_organization, feature_category: :webhooks do
  let_it_be(:user) { create(:admin) }
  let_it_be_with_refind(:web_hook) { create(:system_hook, organization: current_organization) }
  let_it_be_with_refind(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }

  it_behaves_like WebHooks::HookLogActions do
    let!(:show_path) { admin_hook_hook_log_path(web_hook, web_hook_log) }
    let!(:retry_path) { retry_admin_hook_hook_log_path(web_hook, web_hook_log) }
    let(:edit_hook_path) { edit_admin_hook_path(web_hook) }
  end

  context 'when the hook belongs to another organization' do
    let_it_be(:other_organization) { create(:organization) }
    let_it_be_with_refind(:other_hook) { create(:system_hook, organization: other_organization) }
    let_it_be_with_refind(:other_hook_log) { create(:web_hook_log, web_hook: other_hook) }

    before do
      sign_in(user)
    end

    describe 'GET #show' do
      it 'renders a 404' do
        get admin_hook_hook_log_path(other_hook, other_hook_log)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'POST #retry' do
      it 'renders a 404 and does not resend the hook' do
        stub_request(:post, other_hook.interpolated_url)

        post retry_admin_hook_hook_log_path(other_hook, other_hook_log)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(WebMock).not_to have_requested(:post, other_hook.interpolated_url)
      end
    end
  end
end
