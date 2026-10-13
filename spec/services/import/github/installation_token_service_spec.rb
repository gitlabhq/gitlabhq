# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::InstallationTokenService, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  let(:installation_id) { 42 }
  let(:configuration) do
    instance_double(Import::Github::Configuration, app_id: 'app-id', private_key: 'private-key')
  end

  let(:jwt_service) { instance_double(Import::Github::AppJwtService, execute: 'app-jwt') }

  subject(:service) do
    described_class.new(installation_id, configuration: configuration, jwt_service: jwt_service)
  end

  it 'mints a redacting, expiring installation token with fixed read-only permissions' do
    stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
      .with(headers: { 'Authorization' => 'Bearer app-jwt' }, body: token_request_body)
      .to_return(
        status: 201,
        headers: { 'Content-Type' => 'application/json' },
        body: Gitlab::Json.generate(token: 'installation-secret', expires_at: '2026-08-24T13:00:00Z')
      )

    token = service.execute

    expect(token.value).to eq('installation-secret')
    expect(token.expires_at).to eq(Time.zone.parse('2026-08-24 13:00:00 UTC'))
    expect(token.inspect).not_to include('installation-secret')
    expect(described_class::READ_ONLY_PERMISSIONS.values).to all(eq('read'))
  end

  it 'mints a token restricted to the requested repository identity' do
    stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
      .with(
        headers: { 'Authorization' => 'Bearer app-jwt' },
        body: token_request_body(repository_ids: [101])
      )
      .to_return(
        status: 201,
        headers: { 'Content-Type' => 'application/json' },
        body: Gitlab::Json.generate(token: 'scoped-secret', expires_at: '2026-08-24T13:00:00Z')
      )

    token = service.execute(repository_id: 101)

    expect(token.value).to eq('scoped-secret')
    expect(token.inspect).not_to include('scoped-secret')
    expect(token).not_to respond_to(:repository_id)
  end

  it 'classifies a rejected repository scope as provider selection loss without leaking the response' do
    stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
      .with(body: token_request_body(repository_ids: [101]))
      .to_return(status: 422, body: 'public repository 101 is not selected; provider-private-response')

    expect { service.execute(repository_id: 101) }
      .to raise_error(described_class::RepositoryNotSelectedError, described_class::REPOSITORY_NOT_SELECTED_MESSAGE)
  end

  it 'retains the ordinary full-installation failure classification for HTTP 422' do
    stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
      .with(body: token_request_body)
      .to_return(status: 422, body: 'provider-private-response')

    expect { service.execute }
      .to raise_error(described_class::TokenRequestError, 'GitHub installation token request failed (HTTP 422)')
  end

  where(:repository_id) do
    [0, -1, '101', Gitlab::Database::MAX_BIGINT_VALUE + 1]
  end

  with_them do
    it 'rejects an invalid repository scope before provider access' do
      expect { service.execute(repository_id: repository_id) }
        .to raise_error(described_class::ConfigurationError, 'GitHub App repository token scope is invalid')
      expect(WebMock).not_to have_requested(:post, %r{api\.github\.com/app/installations})
    end
  end

  it 'raises an error that does not include the provider response body' do
    stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
      .to_return(status: 403, body: 'provider-private-response')

    expect { service.execute }
      .to raise_error(described_class::TokenRequestError, 'GitHub installation token request failed (HTTP 403)')
  end

  it 'does not treat a 403 as rate limiting when headers cannot be inspected' do
    response = instance_double(HTTParty::Response, success?: false, code: 403)
    allow(response).to receive(:headers).and_raise(NoMethodError)
    allow(Gitlab::HTTP).to receive(:post).and_return(response)

    expect { service.execute }
      .to raise_error(described_class::TokenRequestError, 'GitHub installation token request failed (HTTP 403)')
  end

  it 'sanitizes a transport failure raised while requesting a token' do
    allow(Gitlab::HTTP).to receive(:post).and_raise(Gitlab::HTTP::HTTP_ERRORS.first)

    expect { service.execute }
      .to raise_error(described_class::TokenRequestError, /GitHub installation token request failed/)
  end

  it 'raises when the provider response omits a token' do
    stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
      .with(body: token_request_body)
      .to_return(
        status: 201,
        headers: { 'Content-Type' => 'application/json' },
        body: Gitlab::Json.generate(expires_at: 1.hour.from_now.iso8601)
      )

    expect { service.execute }
      .to raise_error(described_class::TokenRequestError, 'GitHub installation token response was incomplete')
  end

  it 'sanitizes a malformed expiry in the provider response' do
    stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
      .with(body: token_request_body)
      .to_return(
        status: 201,
        headers: { 'Content-Type' => 'application/json' },
        body: Gitlab::Json.generate(token: 'installation-secret', expires_at: 'not-a-time')
      )

    expect { service.execute }
      .to raise_error(described_class::TokenRequestError, 'GitHub installation token response was incomplete')
  end

  # A redirect is an untrusted origin transition. The App JWT must remain on the
  # fixed token endpoint rather than being replayed to the Location target.
  it '#security rejects a cross-host redirect without replaying the App credential' do
    redirect_url = 'https://attacker.example.com/github-app-token'
    stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
      .to_return(status: 302, headers: { 'Location' => redirect_url })
    stub_request(:any, redirect_url).to_return(status: 200)

    expect { service.execute }
      .to raise_error(described_class::TokenRequestError, 'GitHub installation token request failed (HTTP 302)')
    expect(WebMock).not_to have_requested(:any, redirect_url)
  end

  where(:status, :headers) do
    429 | {}
    403 | { 'Retry-After' => '60' }
    403 | { 'X-RateLimit-Remaining' => '0' }
  end

  with_them do
    it 'preserves explicit provider throttling as the importer rate-limit contract' do
      stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
        .to_return(status: status, headers: headers, body: 'provider-private-response')

      expect { service.execute }.to raise_error(Gitlab::GithubImport::RateLimitError) do |error|
        expect(error.message).not_to include('provider-private-response')
      end
    end
  end

  it 'raises a configuration error when the App is not configured' do
    allow(configuration).to receive(:private_key).and_return(nil)

    expect { service.execute }
      .to raise_error(described_class::ConfigurationError, 'GitHub App credentials are not configured')
    expect(WebMock).not_to have_requested(:post, %r{api\.github\.com/app/installations})
  end

  context 'with an invalid installation ID' do
    let(:installation_id) { '42/../access_tokens' }

    it 'raises a configuration error before making a provider request' do
      expect { service.execute }
        .to raise_error(described_class::ConfigurationError, 'GitHub App installation ID is invalid')
      expect(WebMock).not_to have_requested(:post, %r{api\.github\.com/app/installations})
    end
  end

  context 'with a non-positive installation ID' do
    let(:installation_id) { 0 }

    it 'raises a configuration error before making a provider request' do
      expect { service.execute }
        .to raise_error(described_class::ConfigurationError, 'GitHub App installation ID is invalid')
      expect(WebMock).not_to have_requested(:post, %r{api\.github\.com/app/installations})
    end
  end

  describe 'token caching', :clean_gitlab_redis_shared_state do
    it 'mints one token per scope and reuses it for repeated calls' do
      request = stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
        .with(body: token_request_body)
        .to_return(
          status: 201,
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.generate(token: 'installation-secret', expires_at: 1.hour.from_now.iso8601)
        )

      first_token = service.execute
      second_token = service.execute

      expect(first_token.value).to eq('installation-secret')
      expect(second_token.value).to eq('installation-secret')
      expect(request).to have_been_requested.once
    end

    it 'stores the cached token encrypted and decrypts it back to the original value on reuse' do
      stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
        .with(body: token_request_body)
        .to_return(
          status: 201,
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.generate(token: 'installation-secret', expires_at: 1.hour.from_now.iso8601)
        )

      service.execute

      raw = Gitlab::Cache::Import::Caching.read('import_sync_github_installation_token:42:', refresh: false)
      expect(raw).not_to include('installation-secret')

      expect(service.execute.value).to eq('installation-secret')
    end

    it 'mints a separate token per repository scope' do
      stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
        .with(body: token_request_body)
        .to_return(
          status: 201,
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.generate(token: 'installation-secret', expires_at: 1.hour.from_now.iso8601)
        )
      stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
        .with(body: token_request_body(repository_ids: [101]))
        .to_return(
          status: 201,
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.generate(token: 'scoped-secret', expires_at: 1.hour.from_now.iso8601)
        )

      expect(service.execute.value).to eq('installation-secret')
      expect(service.execute(repository_id: 101).value).to eq('scoped-secret')
    end

    it 'mints a fresh token when force_refresh is requested' do
      request = stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
        .with(body: token_request_body)
        .to_return(
          { status: 201, headers: { 'Content-Type' => 'application/json' },
            body: Gitlab::Json.generate(token: 'installation-secret', expires_at: 1.hour.from_now.iso8601) },
          { status: 201, headers: { 'Content-Type' => 'application/json' },
            body: Gitlab::Json.generate(token: 'refreshed-secret', expires_at: 2.hours.from_now.iso8601) }
        )

      first_token = service.execute
      refreshed_token = service.execute(force_refresh: true)

      expect(first_token.value).to eq('installation-secret')
      expect(refreshed_token.value).to eq('refreshed-secret')
      expect(request).to have_been_requested.twice
    end

    it 'does not cache a token that is already within the expiry buffer' do
      request = stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
        .with(body: token_request_body)
        .to_return(
          status: 201,
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.generate(token: 'installation-secret', expires_at: 30.seconds.from_now.iso8601)
        )

      service.execute
      service.execute

      expect(request).to have_been_requested.twice
    end

    it 'ignores a malformed cached token and mints a fresh one' do
      Gitlab::Cache::Import::Caching.write('import_sync_github_installation_token:42:', 'not-json')

      request = stub_request(:post, 'https://api.github.com/app/installations/42/access_tokens')
        .with(body: token_request_body)
        .to_return(
          status: 201,
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.generate(token: 'installation-secret', expires_at: 1.hour.from_now.iso8601)
        )

      token = service.execute

      expect(token.value).to eq('installation-secret')
      expect(request).to have_been_requested.once
    end
  end

  # Serializes the only provider permission contract accepted by token-mint specs.
  def token_request_body(repository_ids: nil)
    body = { permissions: described_class::READ_ONLY_PERMISSIONS }
    body[:repository_ids] = repository_ids if repository_ids

    Gitlab::Json.generate(body)
  end
end
