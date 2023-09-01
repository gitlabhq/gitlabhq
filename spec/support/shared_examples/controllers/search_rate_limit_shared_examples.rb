# frozen_string_literal: true

# Requires a context containing:
# - user
# - params

RSpec.shared_examples 'search request exceeding rate limit' do
  include_examples 'rate limited endpoint', rate_limit_key: :search_rate_limit

  it 'allows user in allow-list to search without applying rate limit', :freeze_time,
    :clean_gitlab_redis_rate_limiting do
    allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(:search_rate_limit).and_return(1)

    stub_application_setting(search_rate_limit_allowlist: [current_user.username])

    request
    request

    expect(response).to have_gitlab_http_status(:ok)
  end
end
