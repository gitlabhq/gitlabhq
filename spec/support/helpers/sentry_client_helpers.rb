# frozen_string_literal: true

module SentryClientHelpers
  private

  def stub_sentry_request(url, http_method = :get, body: {}, status: 200, headers: {})
    stub_request(http_method, url)
      .to_return(
        status: status,
        headers: { 'Content-Type' => 'application/json' }.merge(headers),
        body: body.to_json
      )
  end
end
