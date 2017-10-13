require 'spec_helper'

describe Gitlab::LegacyGithubImport::Client do
  let(:token) { '123456' }
  let(:github_provider) { Settingslogic.new('app_id' => 'asd123', 'app_secret' => 'asd123', 'name' => 'github', 'args' => { 'client_options' => {} }) }

  subject(:client) { described_class.new(token) }

  before do
    allow(Gitlab.config.omniauth).to receive(:providers).and_return([github_provider])
  end

  it 'convert OAuth2 client options to symbols' do
    client.client.options.keys.each do |key|
      expect(key).to be_kind_of(Symbol)
    end
  end

  it 'does not crash (e.g. Settingslogic::MissingSetting) when verify_ssl config is not present' do
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
    context 'when provider does not specity an API endpoint' do
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
    end
  end

  it 'does not raise error when rate limit is disabled' do
    stub_request(:get, /api.github.com/)
    allow(client.api).to receive(:rate_limit!).and_raise(Octokit::NotFound)

    expect { client.issues {} }.not_to raise_error
  end
end
