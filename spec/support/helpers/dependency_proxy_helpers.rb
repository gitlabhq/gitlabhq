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
      .to_return(status: status, body: body, headers: headers )
  end

  def stub_blob_download(image, blob_sha, status = 200, body = '123456')
    download_link = registry.blob_url(image, blob_sha)

    stub_full_request(download_link)
      .to_return(status: status, body: body)
  end

  def build_jwt(user = nil, expire_time: nil)
    JSONWebToken::HMACToken.new(::Auth::DependencyProxyAuthenticationService.secret).tap do |jwt|
      jwt['user_id'] = user.id if user
      jwt.expire_time = expire_time || jwt.issued_at + 1.minute
    end
  end

  private

  def registry
    @registry ||= DependencyProxy::Registry
  end
end
