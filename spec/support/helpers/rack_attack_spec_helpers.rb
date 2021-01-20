# frozen_string_literal: true

module RackAttackSpecHelpers
  def api_get_args_with_token_headers(partial_url, token_headers)
    ["/api/#{API::API.version}#{partial_url}", params: nil, headers: token_headers]
  end

  def rss_url(user)
    "/dashboard/projects.atom?feed_token=#{user.feed_token}"
  end

  def private_token_headers(user)
    { 'HTTP_PRIVATE_TOKEN' => user.private_token }
  end

  def personal_access_token_headers(personal_access_token)
    { 'HTTP_PRIVATE_TOKEN' => personal_access_token.token }
  end

  def oauth_token_headers(oauth_access_token)
    { 'AUTHORIZATION' => "Bearer #{oauth_access_token.token}" }
  end

  def basic_auth_headers(user, personal_access_token)
    encoded_login = ["#{user.username}:#{personal_access_token.token}"].pack('m0')
    { 'AUTHORIZATION' => "Basic #{encoded_login}" }
  end

  def expect_rejection(&block)
    yield

    expect(response).to have_gitlab_http_status(:too_many_requests)

    expect(response.headers.to_h).to include(
      'RateLimit-Limit' => a_string_matching(/^\d+$/),
      'RateLimit-Name' => a_string_matching(/^throttle_.*$/),
      'RateLimit-Observed' => a_string_matching(/^\d+$/),
      'RateLimit-Remaining' => a_string_matching(/^\d+$/),
      'Retry-After' => a_string_matching(/^\d+$/)
    )
    expect(response).to have_header('RateLimit-Reset')
    expect do
      DateTime.strptime(response.headers['RateLimit-Reset'], '%s')
    end.not_to raise_error
    expect(response).to have_header('RateLimit-ResetTime')
    expect do
      Time.httpdate(response.headers['RateLimit-ResetTime'])
    end.not_to raise_error
  end

  def expect_ok(&block)
    yield

    expect(response).to have_gitlab_http_status(:ok)
  end

  def random_next_ip
    allow_next_instance_of(Rack::Attack::Request) do |instance|
      allow(instance).to receive(:ip).and_return(FFaker::Internet.ip_v4_address)
    end
  end
end
