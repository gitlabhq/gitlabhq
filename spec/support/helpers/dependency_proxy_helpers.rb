# frozen_string_literal: true

module DependencyProxyHelpers
  include StubRequests

  def stub_registry_auth(image, token, status = 200, body = nil)
    auth_body = { 'token' => token }.to_json
    auth_link = registry.auth_url(image)

    stub_full_request(auth_link)
      .to_return(status: status, body: body || auth_body)
  end

  def stub_manifest_download(image, tag, status: 200, body: nil, headers: {})
    manifest_url = registry.manifest_url(image, tag)

    stub_full_request(manifest_url)
      .to_return(status: status, body: body || manifest, headers: headers)
  end

  def stub_manifest_head(image, tag, status: 200, body: nil, headers: {})
    manifest_url = registry.manifest_url(image, tag)

    stub_full_request(manifest_url, method: :head)
      .to_return(status: status, body: body, headers: headers)
  end

  def stub_blob_download(image, blob_sha, status = 200, body = '123456')
    download_link = registry.blob_url(image, blob_sha)

    stub_full_request(download_link)
      .to_return(status: status, body: body)
  end

  def build_jwt(user_or_token = nil, expire_time: nil)
    JSONWebToken::HMACToken.new(::Auth::DependencyProxyAuthenticationService.secret).tap do |jwt|
      if block_given?
        yield(jwt)
      else
        jwt['user_id'] = user_or_token.id if user_or_token.is_a?(User)
        jwt['personal_access_token'] = user_or_token.token if user_or_token.is_a?(PersonalAccessToken)
        jwt['deploy_token'] = user_or_token.token if user_or_token.is_a?(DeployToken)
        jwt.expire_time = expire_time || (jwt.issued_at + 1.minute)
      end
    end
  end

  def jwt_token_authorization_headers(jwt)
    { 'AUTHORIZATION' => "Bearer #{jwt.encoded}" }
  end

  private

  def registry
    @registry ||= DependencyProxy::Registry
  end
end
