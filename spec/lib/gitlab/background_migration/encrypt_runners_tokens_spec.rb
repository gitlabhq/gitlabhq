# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::EncryptRunnersTokens, :migration, schema: 20181121111200 do
  let(:settings) { table(:application_settings) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:runners) { table(:ci_runners) }

  context 'when migrating application settings' do
    before do
      settings.create!(id: 1, runners_registration_token: 'plain-text-token1')
    end

    it 'migrates runners registration tokens' do
      migrate!(:settings, 1, 1)

      encrypted_token = settings.first.runners_registration_token_encrypted
      decrypted_token = ::Gitlab::CryptoHelper.aes256_gcm_decrypt(encrypted_token)

      expect(decrypted_token).to eq 'plain-text-token1'
      expect(settings.first.runners_registration_token).to eq 'plain-text-token1'
    end
  end

  context 'when migrating namespaces' do
    before do
      namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab-org', runners_token: 'my-token1')
      namespaces.create!(id: 12, name: 'gitlab', path: 'gitlab-org', runners_token: 'my-token2')
      namespaces.create!(id: 22, name: 'gitlab', path: 'gitlab-org', runners_token: 'my-token3')
    end

    it 'migrates runners registration tokens' do
      migrate!(:namespace, 11, 22)

      expect(namespaces.all.reload).to all(
        have_attributes(runners_token: be_a(String), runners_token_encrypted: be_a(String))
      )
    end
  end

  context 'when migrating projects' do
    before do
      namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab-org')
      projects.create!(id: 111, namespace_id: 11, name: 'gitlab', path: 'gitlab-ce', runners_token: 'my-token1')
      projects.create!(id: 114, namespace_id: 11, name: 'gitlab', path: 'gitlab-ce', runners_token: 'my-token2')
      projects.create!(id: 116, namespace_id: 11, name: 'gitlab', path: 'gitlab-ce', runners_token: 'my-token3')
    end

    it 'migrates runners registration tokens' do
      migrate!(:project, 111, 116)

      expect(projects.all.reload).to all(
        have_attributes(runners_token: be_a(String), runners_token_encrypted: be_a(String))
      )
    end
  end

  context 'when migrating runners' do
    before do
      runners.create!(id: 201, runner_type: 1, token: 'plain-text-token1')
      runners.create!(id: 202, runner_type: 1, token: 'plain-text-token2')
      runners.create!(id: 203, runner_type: 1, token: 'plain-text-token3')
    end

    it 'migrates runners communication tokens' do
      migrate!(:runner, 201, 203)

      expect(runners.all.reload).to all(
        have_attributes(token: be_a(String), token_encrypted: be_a(String))
      )
    end
  end

  def migrate!(model, from, to)
    subject.perform(model, from, to)
  end
end
