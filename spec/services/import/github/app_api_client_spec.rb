# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::AppApiClient, feature_category: :importers do
  let(:jwt_service) { instance_double(Import::Github::AppJwtService, execute: 'app-jwt') }
  let(:response) do
    instance_double(
      HTTParty::Response,
      success?: true,
      code: 200,
      body: Gitlab::Json.generate(payload),
      headers: {}
    )
  end

  let(:payload) { { id: 44, account: { id: 55, login: 'gitlab-org' } } }

  subject(:client) { described_class.new(jwt_service: jwt_service) }

  before do
    allow(Import::Clients::HTTP).to receive(:get).and_return(response)
  end

  it 'reads installation metadata from the fixed GitHub API origin with an App JWT' do
    expect(client.installation(44)).to include(id: 44, account: include(id: 55))
    expect(Import::Clients::HTTP).to have_received(:get).with(
      'https://api.github.com/app/installations/44',
      headers: hash_including(
        'Accept' => 'application/vnd.github+json',
        'Authorization' => 'Bearer app-jwt',
        'X-GitHub-Api-Version' => '2022-11-28'
      ),
      timeout: 30,
      follow_redirects: false
    )
  end

  # Reinstallation recovery must discover only the installation selected for the retained repository.
  # The exact fixed-origin request proves reconnect cannot enumerate unrelated App installations.
  it 'reads the repository installation through the App JWT endpoint without redirects' do
    expect(client.repository_installation('gitlab-org/repository.one')).to include(
      id: 44,
      account: include(id: 55)
    )
    expect(Import::Clients::HTTP).to have_received(:get).with(
      'https://api.github.com/repos/gitlab-org/repository.one/installation',
      headers: hash_including(
        'Accept' => 'application/vnd.github+json',
        'Authorization' => 'Bearer app-jwt',
        'X-GitHub-Api-Version' => '2022-11-28'
      ),
      timeout: 30,
      follow_redirects: false
    )
  end

  # Durable provider names cross a database-to-HTTP boundary. Rejecting extra, encoded, empty, and
  # traversal segments before any request proves they cannot redirect the fixed endpoint path.
  it 'rejects malformed repository identities before any provider request' do
    invalid_full_names = [
      '',
      'gitlab-org',
      'gitlab-org/',
      '/repository',
      'gitlab-org/repository/installation',
      'gitlab-org/../installation',
      'gitlab-org/%2Finstallation',
      'gitlab-org/repository?per_page=100'
    ]

    invalid_full_names.each do |full_name|
      expect { client.repository_installation(full_name) }
        .to raise_error(described_class::ProviderError, 'GitHub App request failed')
    end

    expect(Import::Clients::HTTP).not_to have_received(:get)
  end

  it 'keeps a repository redirect inside the sanitized provider-unavailable boundary' do
    allow(response).to receive_messages(success?: false, code: 301)

    expect { client.repository_installation('gitlab-org/repository') }
      .to raise_error(described_class::ProviderError, 'GitHub App request failed')
  end

  it 'rejects invalid installation IDs before any provider request' do
    expect { client.installation('../tokens') }
      .to raise_error(described_class::ProviderError, 'GitHub App request failed')
    expect(Import::Clients::HTTP).not_to have_received(:get)
  end

  it 'sanitizes unsuccessful and malformed provider responses' do
    allow(response).to receive_messages(success?: false, code: 403)
    expect { client.application }.to raise_error(described_class::ProviderError)

    allow(response).to receive_messages(success?: true, body: '[]')
    expect { client.application }.to raise_error(described_class::ProviderError)
  end

  it 'distinguishes an authoritative installation 404 from other provider failures' do
    allow(response).to receive_messages(success?: false, code: 404)

    expect { client.installation(44) }
      .to raise_error(described_class::InstallationNotFoundError)
    expect { client.repository_installation('gitlab-org/repository') }
      .to raise_error(described_class::RepositoryInstallationNotFoundError)
    expect { client.application }.to raise_error(described_class::ProviderError)
  end

  it 'distinguishes explicit 429 and exhausted 403 responses from provider outages' do
    allow(response).to receive_messages(success?: false, code: 429)
    expect { client.application }.to raise_error(described_class::RateLimitError)

    allow(response).to receive_messages(code: 403, headers: { 'X-RateLimit-Remaining' => '0' })
    expect { client.application }.to raise_error(described_class::RateLimitError)

    allow(response).to receive_messages(headers: {})
    expect { client.application }.to raise_error(described_class::ProviderError)
  end

  it 'does not treat a 403 as rate limiting when headers cannot be inspected' do
    allow(response).to receive_messages(success?: false, code: 403)
    allow(response).to receive(:headers).and_raise(NoMethodError)

    expect { client.application }.to raise_error(described_class::ProviderError)
  end

  it 'rejects a non-positive installation ID before any provider request' do
    expect { client.installation(0) }
      .to raise_error(described_class::ProviderError, 'GitHub App request failed')
    expect(Import::Clients::HTTP).not_to have_received(:get)
  end

  it 'sanitizes a transport failure raised while fetching a provider response' do
    allow(Import::Clients::HTTP).to receive(:get).and_raise(Gitlab::HTTP::HTTP_ERRORS.first)

    expect { client.application }.to raise_error(described_class::ProviderError, 'GitHub App request failed')
  end

  it 'omits provider credentials from inspection' do
    expect(client.inspect).to eq("#<#{described_class.name}>")
  end
end
