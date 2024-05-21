# frozen_string_literal: true

module GitlabShellHelpers
  extend self

  def gitlab_shell_internal_api_request_header(
    issuer: Gitlab::Shell::JWT_ISSUER, secret_token: Gitlab::Shell.secret_token)
    jwt_token = JSONWebToken::HMACToken.new(secret_token).tap do |token|
      token.issuer = issuer
    end

    { Gitlab::Shell::API_HEADER => jwt_token.encoded }
  end
end
