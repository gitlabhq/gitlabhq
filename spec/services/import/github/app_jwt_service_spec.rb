# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::AppJwtService, feature_category: :importers do
  let(:key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:configuration) do
    instance_double(
      Import::Github::Configuration,
      app_id: '12345',
      private_key: key.to_pem
    )
  end

  let(:current_time) { Time.current.change(usec: 0) }

  subject(:service) do
    described_class.new(configuration: configuration, current_time: -> { current_time })
  end

  it 'creates a short-lived RS256 token with GitHub App claims' do
    payload, headers = JWT.decode(service.execute, key.public_key, true, algorithm: 'RS256')

    expect(configuration).to have_received(:private_key).once
    expect(headers['alg']).to eq('RS256')
    expect(payload).to include(
      'iss' => '12345',
      'iat' => (current_time - 60.seconds).to_i,
      'exp' => (current_time + 9.minutes).to_i
    )
  end

  it 'does not include the private key in a configuration failure' do
    allow(configuration).to receive(:private_key).and_return('not-a-private-key')

    expect { service.execute }
      .to raise_error(described_class::ConfigurationError, 'GitHub App private key is invalid')
  end

  context 'with a file-backed configuration' do
    let(:configuration) { Import::Github::Configuration.new }
    let(:private_key_path) { '/configured/github-app-private-key.pem' }

    before do
      stub_env(Import::Github::Configuration::APP_ID_ENV, '12345')
      stub_env(Import::Github::Configuration::PRIVATE_KEY_ENV, nil)
      stub_env(Import::Github::Configuration::PRIVATE_KEY_FILE_ENV, private_key_path)
    end

    # Protects the JWT boundary from a stale key path. The exact fixed message
    # proves neither the configured path nor the operating-system detail escaped.
    it 'sanitizes a missing private-key file as a configuration error' do
      allow(File).to receive(:binread).with(private_key_path).and_raise(Errno::ENOENT)

      expect { service.execute }
        .to raise_error(described_class::ConfigurationError, 'GitHub App credentials are not configured')
    end

    # Protects the equivalent deployment-permission failure while retaining the
    # same public error contract used for every unavailable App credential.
    it 'sanitizes an unreadable private-key file as a configuration error' do
      allow(File).to receive(:binread).with(private_key_path).and_raise(Errno::EACCES)

      expect { service.execute }
        .to raise_error(described_class::ConfigurationError, 'GitHub App credentials are not configured')
    end
  end
end
