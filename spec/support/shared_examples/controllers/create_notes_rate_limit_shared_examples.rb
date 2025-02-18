# frozen_string_literal: true

#
# Requires a context containing:
# - user
# - params

RSpec.shared_examples 'create notes request exceeding rate limit' do
  include_examples 'rate limited endpoint', rate_limit_key: :notes_create

  it 'allows user in allow-list to create notes, even if the case is different', :freeze_time, :clean_gitlab_redis_rate_limiting do
    allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(:notes_create).and_return(1)

    current_user.update_attribute(:username, current_user.username.titleize)
    stub_application_setting(notes_create_limit_allowlist: [current_user.username.downcase])

    request
    request

    expect(response).to have_gitlab_http_status(:found)
  end
end
