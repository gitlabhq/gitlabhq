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
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      before do
        sign_in current_user
      end

      def request
        get merge_requests_dashboard_path, params: { scope: 'all', search: 'test' }
      end
    end

    context 'when merge_request_dashboard feature flag is enabled' do
      before do
        stub_feature_flags(merge_request_dashboard: true)

        sign_in current_user
      end

      it 'redirects to search page with the current query string' do
        get merge_requests_dashboard_path, params: { assignee_username: current_user.username }

        expect(response).to redirect_to(merge_requests_search_dashboard_path(params: { assignee_username: current_user.username }))
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

  shared_examples 'load project events' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user1) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:events) { create_list(:event, 25, author: user1, project: project) } # rubocop:disable FactoryBot/ExcessiveCreateList -- We need more than 20 events to demonstrate how the controller limits the amount of returned objects

    before_all do
      project.add_developer(current_user)
      current_user.toggle_star(project)
    end

    before do
      sign_in current_user
    end

    it 'returns 20 events by default' do
      get activity_dashboard_path, params: { filter: filter }, as: :json

      expect(json_response['count']).to be(20)
    end

    it 'returns the requested number of events' do
      get activity_dashboard_path, params: { filter: filter, limit: 10 }, as: :json

      expect(json_response['count']).to be(10)
    end

    it 'returns the default amount of events if the `limit` parameter is invalid' do
      get activity_dashboard_path, params: { filter: filter, limit: 'user input' }, as: :json

      expect(json_response['count']).to be(20)
    end
  end

  context "when fetching user's projects activity" do
    let_it_be(:filter) { 'projects' }

    it_behaves_like 'load project events'
  end

  context 'when fetching starred projects activity' do
    let_it_be(:filter) { 'starred' }

    it_behaves_like 'load project events'
  end
end
