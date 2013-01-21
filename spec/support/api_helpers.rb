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
  def api(path, user = nil)
    "/api/#{Gitlab::API.version}#{path}" +

      # Normalize query string
      (path.index('?') ? '' : '?') +

      # Append private_token if given a User object
      (user.respond_to?(:private_token) ?
        "&private_token=#{user.private_token}" : "")
  end

  def json_response
    JSON.parse(response.body)
  end
end
