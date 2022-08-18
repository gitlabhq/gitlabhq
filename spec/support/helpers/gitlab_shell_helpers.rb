# frozen_string_literal: true

module GitlabShellHelpers
  extend self

  def gitlab_shell_internal_api_request_header(
    issuer: API::Helpers::GITLAB_SHELL_JWT_ISSUER, secret_token: Gitlab::Shell.secret_token)
    jwt_token = JSONWebToken::HMACToken.new(secret_token).tap do |token|
      token.issuer = issuer
    end

    { API::Helpers::GITLAB_SHELL_API_HEADER => jwt_token.encoded }
  end
end
