# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardController, feature_category: :system_access do
  context 'token authentication' do
    it_behaves_like 'authenticates sessionless user for the request spec', 'issues atom', public_resource: false do
      let(:url) { issues_dashboard_url(:atom, assignee_username: user.username) }
    end

    it_behaves_like 'authenticates sessionless user for the request spec', 'issues_calendar ics', public_resource: false do
      let(:url) { issues_dashboard_url(:ics, assignee_username: user.username) }
    end
  end

  context 'issues dashboard' do
    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      let_it_be(:current_user) { create(:user) }

      before do
        sign_in current_user
      end

      def request
        get issues_dashboard_path, params: { scope: 'all', search: 'test' }
      end
    end
  end

  context 'merge requests dashboard' do
    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      let_it_be(:current_user) { create(:user) }

      before do
        sign_in current_user
      end

      def request
        get merge_requests_dashboard_path, params: { scope: 'all', search: 'test' }
      end
    end
  end

  context 'search merge requests dashboard' do
    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      let_it_be(:current_user) { create(:user) }

      before do
        sign_in current_user
      end

      def request
        get merge_requests_search_dashboard_path, params: { scope: 'all', search: 'test' }
      end
    end
  end
end
