require 'spec_helper'

describe Gitlab::GithubImport::Client, lib: true do
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

  context 'allow SSL verification to be configurable on API' do
    before do
      github_provider['verify_ssl'] = false
    end

    it 'uses supplied value' do
      expect(client.client.options[:connection_opts][:ssl]).to eq({ verify: false })
      expect(client.api.connection_options[:ssl]).to eq({ verify: false })
    end
  end

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
end
