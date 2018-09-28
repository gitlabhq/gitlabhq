module GitHttpHelpers
  def clone_get(project, options = {})
    get "/#{project}/info/refs", { service: 'git-upload-pack' }, auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def clone_post(project, options = {})
    post "/#{project}/git-upload-pack", {}, auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def push_get(project, options = {})
    get "/#{project}/info/refs", { service: 'git-receive-pack' }, auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def push_post(project, options = {})
    post "/#{project}/git-receive-pack", {}, auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def download(project, user: nil, password: nil, spnego_request_token: nil)
    args = [project, { user: user, password: password, spnego_request_token: spnego_request_token }]

    clone_get(*args)
    yield response

    clone_post(*args)
    yield response
  end

  def upload(project, user: nil, password: nil, spnego_request_token: nil)
    args = [project, { user: user, password: password, spnego_request_token: spnego_request_token }]

    push_get(*args)
    yield response

    push_post(*args)
    yield response
  end

  def download_or_upload(*args, &block)
    download(*args, &block)
    upload(*args, &block)
  end

  def auth_env(user, password, spnego_request_token)
    env = workhorse_internal_api_request_header
    if user
      env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
    elsif spnego_request_token
      env['HTTP_AUTHORIZATION'] = "Negotiate #{::Base64.strict_encode64('opaque_request_token')}"
    end

    env
  end

  def git_access_error(error_key)
    message = Gitlab::GitAccess::ERROR_MESSAGES[error_key]
    message || raise("GitAccess error message key '#{error_key}' not found")
  end

  def git_access_wiki_error(error_key)
    message = Gitlab::GitAccessWiki::ERROR_MESSAGES[error_key]
    message || raise("GitAccessWiki error message key '#{error_key}' not found")
  end

  def change_access_error(error_key)
    message = Gitlab::Checks::ChangeAccess::ERROR_MESSAGES[error_key]
    message || raise("ChangeAccess error message key '#{error_key}' not found")
  end
end
