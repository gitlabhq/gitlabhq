# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::Configuration, feature_category: :importers do
  subject(:configuration) { described_class.new }

  before do
    stub_env(described_class::APP_ID_ENV, nil)
    stub_env(described_class::PRIVATE_KEY_ENV, nil)
    stub_env(described_class::PRIVATE_KEY_FILE_ENV, nil)
    stub_env(described_class::WEBHOOK_SECRET_ENV, nil)
  end

  it 'is not configured without explicit credentials' do
    expect(configuration).not_to be_configured
  end

  it 'has no private key when neither the inline value nor a file path is configured' do
    expect(configuration.private_key).to be_nil
  end

  it 'reads explicit App credentials without exposing them through inspect' do
    stub_env(described_class::APP_ID_ENV, '123')
    stub_env(described_class::PRIVATE_KEY_ENV, 'private-key')
    stub_env(described_class::WEBHOOK_SECRET_ENV, 'webhook-secret')

    expect(configuration).to be_configured
    expect(configuration.inspect).not_to include('private-key', 'webhook-secret')
  end

  context 'with a file-backed private key' do
    let(:private_key_path) { '/configured/github-app-private-key.pem' }

    before do
      stub_env(described_class::APP_ID_ENV, '123')
      stub_env(described_class::PRIVATE_KEY_FILE_ENV, private_key_path)
      stub_env(described_class::WEBHOOK_SECRET_ENV, 'webhook-secret')
      allow(File).to receive(:file?).with(private_key_path).and_return(true)
      allow(File).to receive(:readable?).with(private_key_path).and_return(true)
      allow(File).to receive(:binread).with(private_key_path).and_return('file-private-key')
    end

    it 'is configured only from a regular readable file and returns its key bytes' do
      expect(configuration).to be_configured
      expect(configuration.private_key).to eq('file-private-key')
    end

    # Protects startup readiness from a stale deployment path. Neither the path
    # nor its operating-system error may escape the configuration boundary.
    it 'is not configured when the private-key file is missing' do
      allow(File).to receive(:file?).with(private_key_path).and_return(false)
      allow(File).to receive(:binread).with(private_key_path).and_raise(Errno::ENOENT)

      expect(configuration).not_to be_configured
      expect(configuration.private_key).to be_nil
      expect(configuration.inspect).not_to include(private_key_path)
    end

    # Protects the same readiness contract when a path exists but the GitLab
    # process cannot read it; no provider flow should advertise usable credentials.
    it 'is not configured when the private-key file is unreadable' do
      allow(File).to receive(:readable?).with(private_key_path).and_return(false)
      allow(File).to receive(:binread).with(private_key_path).and_raise(Errno::EACCES)

      expect(configuration).not_to be_configured
      expect(configuration.private_key).to be_nil
    end

    # Simulates a file disappearing after the metadata readiness check. Returning
    # nil lets AppJwtService produce its fixed ConfigurationError without OS details.
    it 'sanitizes a private-key read race after configuration was ready' do
      allow(File).to receive(:binread).with(private_key_path).and_raise(Errno::ENOENT)

      expect(configuration).to be_configured
      expect(configuration.private_key).to be_nil
    end

    it 'is not configured when checking the private-key file path raises an OS error' do
      allow(File).to receive(:file?).with(private_key_path).and_raise(Errno::ENAMETOOLONG)

      expect(configuration).not_to be_configured
    end
  end
end
