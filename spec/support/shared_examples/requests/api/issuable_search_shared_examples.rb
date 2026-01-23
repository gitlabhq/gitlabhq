# frozen_string_literal: true

RSpec.shared_examples 'issuable API rate-limited search' do
  context 'when authenticated' do
    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      let(:current_user) { user }

      def request
        get api(url, current_user), params: { scope: 'all', search: issuable.title }
      end

      def request_with_second_scope
        get api(url, user2), params: { scope: 'all', search: issuable.title }
      end
    end

    it 'allows user in search_rate_limit_allowlist to bypass rate limits', :freeze_time,
      :clean_gitlab_redis_rate_limiting do
      allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).and_call_original
      allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(:search_rate_limit).and_return(1)

      stub_application_setting(search_rate_limit_allowlist: [user.username])

      def make_request
        get api(url, user), params: { scope: 'all', search: issuable.title }
      end

      2.times { make_request }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'when unauthenticated' do
    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit_unauthenticated do
      def request
        get api(url), params: { scope: 'all', search: issuable.title }
      end

      def request_with_second_scope
        get api(url), params: { scope: 'all', search: issuable.title }, headers: { 'REMOTE_ADDR' => '1.2.3.4' }
      end
    end
  end
end
