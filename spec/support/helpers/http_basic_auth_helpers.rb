# frozen_string_literal: true

module HttpBasicAuthHelpers
  def user_basic_auth_header(user)
    access_token = create(:personal_access_token, user: user)

    basic_auth_header(user.username, access_token.token)
  end

  def job_basic_auth_header(job)
    basic_auth_header(Ci::Build::CI_REGISTRY_USER, job.token)
  end

  def client_basic_auth_header(client)
    basic_auth_header(client.uid, client.secret)
  end

  def basic_auth_header(username, password)
    {
      'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(
        username,
        password
      )
    }
  end
end
