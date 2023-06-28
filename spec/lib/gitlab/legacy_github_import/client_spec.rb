# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::Client, feature_category: :importers do
  let(:token) { '123456' }
  let(:github_provider) { GitlabSettings::Options.build('app_id' => 'asd123', 'app_secret' => 'asd123', 'name' => 'github', 'args' => { 'client_options' => client_options }) }
  let(:client_options) { {} }
  let(:wait_for_rate_limit_reset) { true }

  subject(:client) { described_class.new(token, wait_for_rate_limit_reset: wait_for_rate_limit_reset) }

  before do
    allow(Gitlab.config.omniauth).to receive(:providers).and_return([github_provider])
  end

  context 'with client options' do
    let(:client_options) do
      {
        'authorize_url' => 'https://github.com/login/oauth/authorize',
        'token_url' => 'https://github.com/login/oauth/access_token'
      }
    end

    it 'convert OAuth2 client options to symbols' do
      expect(client.client.options.keys).to all(be_kind_of(Symbol))
      expect(client.client.options[:authorize_url]).to eq(client_options['authorize_url'])
      expect(client.client.options[:token_url]).to eq(client_options['token_url'])
    end
  end

  it 'does not crash (e.g. GitlabSettings::MissingSetting) when verify_ssl config is not present' do
    expect { client.api }.not_to raise_error
  end

  context 'when config is missing' do
    before do
      allow(Gitlab.config.omniauth).to receive(:providers).and_return([])
    end

    it 'is still possible to get an Octokit client' do
      expect { client.api }.not_to raise_error
    end

    it 'is not be possible to get an OAuth2 client' do
      expect { client.client }.to raise_error(Projects::ImportService::Error)
    end
  end

  context 'allow SSL verification to be configurable on API' do
    before do
      github_provider['verify_ssl'] = false
    end

    it 'uses supplied value' do
      expect(client.client.options[:connection_opts][:ssl]).to eq({ verify: false })
      expect(client.api.connection_options[:ssl]).to eq({ verify: false })
    end
  end

  describe '#api_endpoint' do
    context 'when provider does not specify an API endpoint' do
      it 'uses GitHub root API endpoint' do
        expect(client.api.api_endpoint).to eq 'https://api.github.com/'
      end
    end

    context 'when provider specify a custom API endpoint' do
      before do
        github_provider['args']['client_options']['site'] = 'https://github.company.com/'
      end

      it 'uses the custom API endpoint' do
        expect(OmniAuth::Strategies::GitHub).not_to receive(:default_options)
        expect(client.api.api_endpoint).to eq 'https://github.company.com/'
      end
    end

    context 'when given a host' do
      subject(:client) { described_class.new(token, host: 'https://try.gitea.io/') }

      it 'builds a endpoint with the given host and the default API version' do
        expect(client.api.api_endpoint).to eq 'https://try.gitea.io/api/v3/'
      end
    end

    context 'when given an API version' do
      subject(:client) { described_class.new(token, api_version: 'v3') }

      it 'does not use the API version without a host' do
        expect(client.api.api_endpoint).to eq 'https://api.github.com/'
      end
    end

    context 'when given a host and version' do
      subject(:client) { described_class.new(token, host: 'https://try.gitea.io/', api_version: 'v3') }

      it 'builds a endpoint with the given options' do
        expect(client.api.api_endpoint).to eq 'https://try.gitea.io/api/v3/'
      end

      context 'and hostname' do
        subject(:client) { described_class.new(token, host: 'https://167.99.148.217/', api_version: 'v1', hostname: 'try.gitea.io') }

        it 'builds a endpoint with the given options' do
          expect(client.api.connection_options.dig(:headers, :host)).to eq 'try.gitea.io'
          expect(client.api.api_endpoint).to eq 'https://167.99.148.217/api/v1/'
        end
      end
    end
  end

  describe '#repository' do
    it 'returns repository data as a hash' do
      stub_request(:get, 'https://api.github.com/rate_limit')
        .to_return(status: 200, headers: { 'X-RateLimit-Limit' => 5000, 'X-RateLimit-Remaining' => 5000 })

      stub_request(:get, 'https://api.github.com/repositories/1')
        .to_return(status: 200, body: { id: 1 }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(client.repository(1)).to eq({ id: 1 })
    end
  end

  describe '#repos' do
    it 'returns the user\'s repositories as a hash' do
      stub_request(:get, 'https://api.github.com/rate_limit')
        .to_return(status: 200, headers: { 'X-RateLimit-Limit' => 5000, 'X-RateLimit-Remaining' => 5000 })

      stub_request(:get, 'https://api.github.com/user/repos')
        .to_return(status: 200, body: [{ id: 1 }, { id: 2 }].to_json, headers: { 'Content-Type' => 'application/json' })

      expect(client.repos).to match_array([{ id: 1 }, { id: 2 }])
    end
  end

  context 'github rate limit' do
    it 'does not raise error when rate limit is disabled' do
      stub_request(:get, /api.github.com/)
      allow(client.api).to receive(:rate_limit!).and_raise(Octokit::NotFound)

      expect { client.repos }.not_to raise_error
    end

    context 'when wait for rate limit is disabled' do
      let(:wait_for_rate_limit_reset) { false }

      it 'raises the error limit error when requested' do
        stub_request(:get, /api.github.com/)
        allow(client.api).to receive(:repos).and_raise(Octokit::TooManyRequests)

        expect { client.repos }.to raise_error(Octokit::TooManyRequests)
      end
    end
  end
end
