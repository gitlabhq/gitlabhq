# frozen_string_literal: true

require_relative 'workhorse_helpers'

module GitHttpHelpers
  include WorkhorseHelpers

  def clone_get(repository_path, **options)
    get "/#{repository_path}/info/refs", params: { service: 'git-upload-pack' }, headers: auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def clone_post(repository_path, **options)
    post "/#{repository_path}/git-upload-pack", headers: auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def push_get(repository_path, **options)
    get "/#{repository_path}/info/refs", params: { service: 'git-receive-pack' }, headers: auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def push_post(repository_path, **options)
    post "/#{repository_path}/git-receive-pack", headers: auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def download(repository_path, user: nil, password: nil, spnego_request_token: nil)
    args = { user: user, password: password, spnego_request_token: spnego_request_token }

    clone_get(repository_path, **args)
    yield response

    clone_post(repository_path, **args)
    yield response
  end

  def upload(repository_path, user: nil, password: nil, spnego_request_token: nil)
    args = { user: user, password: password, spnego_request_token: spnego_request_token }

    push_get(repository_path, **args)
    yield response

    push_post(repository_path, **args)
    yield response
  end

  def download_or_upload(repository_path, **args, &block)
    download(repository_path, **args, &block)
    upload(repository_path, **args, &block)
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
end
