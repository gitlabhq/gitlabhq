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
    "/api/#{version}#{path}" +

      # Normalize query string
      (path.index('?') ? '' : '?') +

      if personal_access_token.present?
        "&private_token=#{personal_access_token.token}"
      elsif oauth_access_token.present?
        "&access_token=#{oauth_access_token.token}"
      # Append private_token if given a User object
      elsif user.respond_to?(:private_token)
        "&private_token=#{user.private_token}"
      else
        ''
      end
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

  def ci_api(path, user = nil)
    "/ci/api/v1/#{path}" +

      # Normalize query string
      (path.index('?') ? '' : '?') +

      # Append private_token if given a User object
      if user.respond_to?(:private_token)
        "&private_token=#{user.private_token}"
      else
        ''
      end
  end
end
