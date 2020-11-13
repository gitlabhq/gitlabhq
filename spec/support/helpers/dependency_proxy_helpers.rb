# frozen_string_literal: true

module DependencyProxyHelpers
  include StubRequests

  def stub_registry_auth(image, token, status = 200, body = nil)
    auth_body = { 'token' => token }.to_json
    auth_link = registry.auth_url(image)

    stub_full_request(auth_link)
      .to_return(status: status, body: body || auth_body)
  end

  def stub_manifest_download(image, tag, status = 200, body = nil)
    manifest_url = registry.manifest_url(image, tag)

    stub_full_request(manifest_url)
      .to_return(status: status, body: body || manifest)
  end

  def stub_blob_download(image, blob_sha, status = 200, body = '123456')
    download_link = registry.blob_url(image, blob_sha)

    stub_full_request(download_link)
      .to_return(status: status, body: body)
  end

  private

  def registry
    @registry ||= DependencyProxy::Registry
  end
end
