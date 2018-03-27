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

  # Temporary helper method for simplifying V3 exclusive API specs
  def v3_api(path, user = nil, personal_access_token: nil, oauth_access_token: nil)
    api(
      path,
      user,
      version: 'v3',
      personal_access_token: personal_access_token,
      oauth_access_token: oauth_access_token
    )
  end
end
