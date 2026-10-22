# frozen_string_literal: true

require 'spec_helper'

# Kept in its own file: the rate limiter shared examples freeze time and reset the rate limiting
# Redis, which the main listing specs do not expect.
RSpec.describe 'Work item REST list endpoints enforcing the search rate limit',
  feature_category: :portfolio_management do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project, title: 'rate limited search term') }

  shared_examples 'a list route enforcing the search rate limit' do
    context 'when authenticated' do
      it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
        let(:current_user) { user }

        def request
          get api(path, user), params: { search: work_item.title }
        end

        def request_with_second_scope
          get api(path, other_user), params: { search: work_item.title }
        end
      end

      it 'lets users in the search_rate_limit_allowlist bypass the limit', :freeze_time,
        :clean_gitlab_redis_rate_limiting do
        allow(Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits)
          .to receive(:limit_for).and_call_original
        allow(Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits)
          .to receive(:limit_for).with(:search_rate_limit, context: anything).and_return(1)
        stub_application_setting(search_rate_limit_allowlist: [user.username])

        2.times { get api(path, user), params: { search: work_item.title } }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when unauthenticated' do
      it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit_unauthenticated do
        def request
          get api(path), params: { search: work_item.title }
        end

        def request_with_second_scope
          get api(path), params: { search: work_item.title }, headers: { 'REMOTE_ADDR' => '1.2.3.4' }
        end
      end
    end

    context 'without a search param' do
      it 'does not consult the search rate limiter' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_call_original
        expect(Gitlab::ApplicationRateLimiter)
          .not_to receive(:throttled_request?).with(anything, anything, :search_rate_limit, any_args)

        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET /namespaces/:id/-/work_items' do
    let(:path) { "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items" }

    it_behaves_like 'a list route enforcing the search rate limit'
  end

  describe 'GET /projects/:id/-/work_items' do
    let(:path) { "/projects/#{project.id}/-/work_items" }

    it_behaves_like 'a list route enforcing the search rate limit'
  end

  describe 'GET /groups/:id/-/work_items' do
    let(:path) { "/groups/#{group.id}/-/work_items" }

    it_behaves_like 'a list route enforcing the search rate limit'
  end
end
