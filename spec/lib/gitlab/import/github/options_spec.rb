require 'spec_helper'

describe Gitlab::Import::Github::Options, lib: true do
  subject(:options) { described_class.new }

  context 'with custom options' do
    let(:github) do
      Settingslogic.new(
        'name' => 'github',
        'app_id' => '123456',
        'app_secret' => '123456',
        'verify_ssl' => false,
        'args' => {
          'client_options' => {
            'site' => 'https://github.mycompany.com',
            'authorize_url' => 'https://github.mycompany.com/login/oauth/authorize',
            'token_url' => 'https://github.mycompany.com/login/oauth/access_token'
          }
        }
      )
    end

    before do
      allow(Gitlab.config.omniauth).to receive(:providers).and_return([github])
    end

    describe '#endpoint' do
      it 'returns custom API endpoint' do
        expect(options.endpoint).to eq 'https://github.mycompany.com'
      end
    end

    describe '#verify_ssl' do
      it 'returns custom value' do
        expect(options.verify_ssl).to eq false
      end
    end
  end

  context 'with default options' do
    before do
      allow(Gitlab.config.omniauth).to receive(:providers).and_return([])
    end

    describe '#endpoint' do
      it 'returns GitHub API endpoint' do
        expect(options.endpoint).to eq 'https://api.github.com'
      end
    end

    describe '#verify_ssl' do
      it 'returns true' do
        expect(options.verify_ssl).to eq true
      end
    end
  end
end
