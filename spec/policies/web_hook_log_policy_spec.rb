# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHookLogPolicy, feature_category: :webhooks do
  describe 'read_web_hook and admin_web_hook' do
    context 'when the webhook log belongs to a project hook' do
      let_it_be(:web_hook, freeze: false) { create(:project_hook) }
      let_it_be(:authorized_user, freeze: false) { create(:user, maintainer_of: web_hook.project) }
      let_it_be(:unauthorized_user, freeze: false) { create(:user, developer_of: web_hook.project) }

      it_behaves_like 'a webhook log policy'
    end

    context 'when the webhook log belongs to a system hook', :enable_admin_mode do
      let_it_be(:web_hook, freeze: false) { create(:system_hook) }
      let_it_be(:authorized_user, freeze: false) { create(:admin) }
      let_it_be(:unauthorized_user, freeze: false) { create(:user) }

      it_behaves_like 'a webhook log policy'
    end
  end
end
