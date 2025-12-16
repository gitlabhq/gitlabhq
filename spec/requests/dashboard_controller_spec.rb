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
        get issues_dashboard_path, params: { scope: 'merge_requests', search: 'test' }
      end

      def request_with_second_scope
        get issues_dashboard_path, params: { scope: 'issues', search: 'test' }
      end
    end
  end

  context 'merge requests dashboard' do
    let_it_be(:current_user) { create(:user) }

    before do
      sign_in current_user
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      def request
        get merge_requests_dashboard_path, params: { scope: 'issues', search: 'test' }
      end

      def request_with_second_scope
        get merge_requests_dashboard_path, params: { scope: 'merge_requests', search: 'test' }
      end
    end

    it 'redirects to search page with the current query string' do
      get merge_requests_dashboard_path, params: { assignee_username: current_user.username }

      expect(response).to redirect_to(merge_requests_search_dashboard_path(params: { assignee_username: current_user.username }))
    end
  end

  context 'search merge requests dashboard' do
    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      let_it_be(:current_user) { create(:user) }

      before do
        sign_in current_user
      end

      def request
        get merge_requests_search_dashboard_path, params: { scope: 'merge_requests', search: 'test' }
      end

      def request_with_second_scope
        get merge_requests_search_dashboard_path, params: { scope: 'issues', search: 'test' }
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

    shared_examples 'returns the default number of project events' do |params|
      it 'returns the default number of events' do
        get activity_dashboard_path, params: { filter: filter }.merge(params), as: :json

        expect(json_response['count']).to be(20)
      end
    end

    describe 'limit parameter validation' do
      context 'when the limit param is not present' do
        it_behaves_like 'returns the default number of project events', {}
      end

      context 'when the param value is negative' do
        it_behaves_like 'returns the default number of project events', { limit: -1 }
      end

      context 'when the param value is non-numeric' do
        it_behaves_like 'returns the default number of project events', { limit: 'woof' }
      end

      context 'when the param value is zero' do
        it_behaves_like 'returns the default number of project events', { limit: 0 }
      end

      context 'when the param value is a valid positive integer' do
        it 'returns the requested number of events' do
          get activity_dashboard_path, params: { filter: filter, limit: 10 }, as: :json

          expect(json_response['count']).to be(10)
        end
      end
    end

    describe 'offset parameter validation' do
      context 'when the offset param is negative' do
        it_behaves_like 'returns the default number of project events', { offset: -1 }
      end

      context 'when the offset param is non-numeric' do
        it_behaves_like 'returns the default number of project events', { offset: 'woof' }
      end
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

  context "when fetching all user activity" do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:recent_project) { create(:project, :public, title: "Recent Project") }
    let_it_be(:old_project) { create(:project, :public, title: "Old Project") }
    let_it_be(:oldest_event) { create(:event, author: current_user, project: old_project, created_at: 2.days.ago.beginning_of_day) }
    let_it_be(:most_recent_event) { create(:event, author: current_user, project: recent_project, created_at: 1.day.ago.beginning_of_day) }

    before do
      sign_in current_user
    end

    describe "limit parameter validation" do
      before do
        stub_const('UserRecentEventsFinder::DEFAULT_LIMIT', 1)
      end

      context "when the limit parameter is not present" do
        it "responds with the default number of events" do
          get activity_dashboard_path, as: :json

          expect(json_response['count']).to be(1)
        end
      end

      context "when the limit param value is negative" do
        it "responds with the default number of events" do
          get activity_dashboard_path, params: { limit: -2 }, as: :json

          expect(json_response['count']).to be(1)
        end
      end

      context "when the limit param value is zero" do
        it "responds with no events" do
          get activity_dashboard_path, params: { limit: 0 }, as: :json

          expect(json_response['count']).to be(0)
        end
      end

      context "when the limit param value is non-numeric" do
        it "responds with no events" do
          get activity_dashboard_path, params: { limit: 'xyz' }, as: :json

          expect(json_response['count']).to be(0)
        end
      end

      context "when the limit parameter value is a valid positive integer" do
        it "responds with the corresponding number of events" do
          get activity_dashboard_path, params: { limit: 2 }, as: :json

          expect(json_response['count']).to be(2)
        end
      end
    end

    shared_examples 'it returns the first page of events' do |params|
      it 'returns the first page of events' do
        get activity_dashboard_path, params: params, as: :json

        expect(json_response['count']).to be(1)
        expect(json_response['html']).to match(/#{recent_project.title}/)
      end
    end

    describe "offset parameter validation" do
      before do
        stub_const('UserRecentEventsFinder::DEFAULT_LIMIT', 1)
      end

      context "when the offset param is not present" do
        it_behaves_like 'it returns the first page of events', {}
      end

      context "when the offset param value is negative" do
        it_behaves_like 'it returns the first page of events', { offset: -2 }
      end

      context "when the offset param value is non-numeric" do
        it_behaves_like 'it returns the first page of events', { offset: 'woof' }
      end

      context "when the offset param value is zero" do
        it_behaves_like 'it returns the first page of events', { offset: 0 }
      end

      context "when the offset param value is a valid positive integer" do
        it "responds with the corresponding page of events" do
          get activity_dashboard_path, params: { offset: 1 }, as: :json

          expect(json_response['count']).to be(1)
          expect(json_response['html']).to match(/#{old_project.title}/)
        end
      end
    end
  end
end
