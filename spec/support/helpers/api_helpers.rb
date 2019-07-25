# frozen_string_literal: true

module ApiHelpers
  # Public: Prepend a request path with the path to the API
  #
  # path - Path to append
  # user - User object - If provided, automatically appends private_token query
  #          string for authenticated requests
  #
  # Examples
  #
  #   >> api('/issues')
  #   => "/api/v2/issues"
  #
  #   >> api('/issues', User.last)
  #   => "/api/v2/issues?private_token=..."
  #
  #   >> api('/issues?foo=bar', User.last)
  #   => "/api/v2/issues?foo=bar&private_token=..."
  #
  # Returns the relative path to the requested API resource
  def api(path, user = nil, version: API::API.version, personal_access_token: nil, oauth_access_token: nil)
    full_path = "/api/#{version}#{path}"

    if oauth_access_token
      query_string = "access_token=#{oauth_access_token.token}"
    elsif personal_access_token
      query_string = "private_token=#{personal_access_token.token}"
    elsif user
      personal_access_token = create(:personal_access_token, user: user)
      query_string = "private_token=#{personal_access_token.token}"
    end

    if query_string
      full_path << (path.index('?') ? '&' : '?')
      full_path << query_string
    end

    full_path
  end

  def expect_paginated_array_response(items)
    expect(response).to have_gitlab_http_status(200)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response.map { |item| item['id'] }).to eq(Array(items))
  end
end
