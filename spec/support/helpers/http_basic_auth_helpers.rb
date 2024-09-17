# frozen_string_literal: true

module HttpBasicAuthHelpers
  def user_basic_auth_header(user, access_token = nil)
    access_token ||= create(:personal_access_token, user: user)

    basic_auth_header(user.username, access_token.token)
  end

  def job_basic_auth_header(job)
    basic_auth_header(::Gitlab::Auth::CI_JOB_USER, job.token)
  end

  def deploy_token_basic_auth_header(deploy_token)
    basic_auth_header(deploy_token.username, deploy_token.token)
  end

  def client_basic_auth_header(client)
    basic_auth_header(client.uid, client.secret)
  end

  def build_auth_headers(value)
    { 'HTTP_AUTHORIZATION' => value }
  end

  def build_token_auth_header(token)
    build_auth_headers("Bearer #{token}")
  end

  def basic_auth_header(username, password)
    build_auth_headers(ActionController::HttpAuthentication::Basic.encode_credentials(username, password))
  end
end
