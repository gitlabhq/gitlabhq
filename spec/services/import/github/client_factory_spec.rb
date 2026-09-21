# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::ClientFactory, feature_category: :importers do
  let(:installation_id) { 42 }
  let(:token) do
    Import::Github::InstallationTokenService::Token.new(
      value: 'installation-secret',
      expires_at: 1.hour.from_now
    )
  end

  let(:token_service) { instance_double(Import::Github::InstallationTokenService) }

  subject(:factory) { described_class.new(installation_id, token_service: token_service) }

  it 'creates an importer-compatible client without exposing its token' do
    allow(token_service).to receive(:execute).with(no_args).and_return(token)
    allow(token_service).to receive(:execute).with(repository_id: nil, force_refresh: true).and_return(token)
    refresh_callback = nil
    expect(Gitlab::GithubImport::Client)
      .to receive(:new)
      .with(
        'installation-secret',
        per_page: 75,
        parallel: false,
        token_refresher: satisfy do |callback|
          refresh_callback = callback
          callback.respond_to?(:call)
        end
      )
      .and_return(:client)

    expect(factory.create(parallel: false, per_page: 75)).to eq(:client)
    expect(refresh_callback.call).to eq('installation-secret')
    expect(token_service).to have_received(:execute).with(no_args).once
    expect(token_service).to have_received(:execute).with(repository_id: nil, force_refresh: true).once
  end

  it 'creates and refreshes a client with the same one-repository token scope' do
    allow(token_service).to receive(:execute).with(repository_id: 123).and_return(token)
    allow(token_service).to receive(:execute)
      .with(repository_id: 123, force_refresh: true).and_return(token)
    refresh_callback = nil
    expect(Gitlab::GithubImport::Client)
      .to receive(:new)
      .with(
        'installation-secret',
        per_page: 75,
        parallel: false,
        token_refresher: satisfy do |callback|
          refresh_callback = callback
          callback.respond_to?(:call)
        end
      )
      .and_return(:client)

    expect(factory.create_for_repository(repository_id: 123, parallel: false, per_page: 75)).to eq(:client)
    expect(refresh_callback.call).to eq('installation-secret')
    expect(token_service).to have_received(:execute).with(repository_id: 123).once
    expect(token_service).to have_received(:execute).with(repository_id: 123, force_refresh: true).once
  end
end
