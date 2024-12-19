# frozen_string_literal: true

require 'spec_helper'
require_relative '../../config/initializers/01_secret_token'

# rubocop:disable RSpec/SpecFilePathFormat -- The initializer name starts with `01` because we want to run it ASAP
# rubocop:disable RSpec/FeatureCategory -- This is a shared responsibility
RSpec.describe SecretsInitializer do
  let(:rails_env_name) { 'test' }
  let(:rails_env) { ActiveSupport::EnvironmentInquirer.new(rails_env_name) }
  let(:fake_secret_file) { Tempfile.new(['fake-secrets', '.yml']) }
  let(:secrets_hash) { {} }
  let(:fake_secret_file_content) { secrets_hash.to_yaml }

  before do
    fake_secret_file.write(fake_secret_file_content)
    fake_secret_file.rewind
  end

  after do
    fake_secret_file.close
    fake_secret_file.unlink
  end

  subject(:initializer) { described_class.new(secrets_file_path: fake_secret_file.path, rails_env: rails_env) }

  describe 'ensure acknowledged secrets in any installations' do
    let(:acknowledged_secrets) do
      %w[secret_key_base otp_key_base db_key_base openid_connect_signing_key encrypted_settings_key_base
        rotated_encrypted_settings_key_base active_record_encryption_primary_key
        active_record_encryption_deterministic_key active_record_encryption_key_derivation_salt]
    end

    it 'does not allow to add a new secret without a proper handling' do
      secrets_hash = YAML.safe_load_file(Rails.root.join('config/secrets.yml'))

      secrets_hash.each_value do |secrets|
        new_secrets = secrets.keys - acknowledged_secrets

        expect(new_secrets).to be_empty,
          <<~WARNING
          CAUTION:
          It looks like you have just added new secret(s) #{new_secrets.inspect} to the secrets.yml.
          Please read the development guide for GitLab secrets at doc/development/application_secrets.md before you proceed this change.
          If you're absolutely sure that the change is safe, please add the new secrets to the 'acknowledged_secrets' in order to silence this warning.
          WARNING
      end
    end
  end

  describe '#secrets_from_file' do
    context 'when the secrets files is a valid YAML' do
      let(:secrets_hash) { { 'foo' => 'bar' } }

      it 'parses and returns the hash' do
        expect(initializer.secrets_from_file).to eq({ 'foo' => 'bar' })
      end
    end

    context 'when the secrets file does not exist' do
      let(:fake_secret_file_content) { 'foo = bar' }

      it 'returns an empty hash' do
        expect(YAML).to receive(:safe_load_file).and_raise(Errno::ENOENT)

        expect(initializer.secrets_from_file).to eq({})
      end
    end

    context 'when the secrets file contains invalid YAML' do
      let(:fake_secret_file_content) { "foo:\n\tbar: baz\n\tbar: foo" }

      it 'raises a Psych::SyntaxError exception' do
        expect { initializer.secrets_from_file }.to raise_error(Psych::SyntaxError)
      end
    end
  end

  describe '#execute!' do
    include StubENV

    let(:allowed_keys) do
      %w[
        secret_key_base
        db_key_base
        otp_key_base
        openid_connect_signing_key
        active_record_encryption_primary_key
        active_record_encryption_deterministic_key
        active_record_encryption_key_derivation_salt
      ]
    end

    let(:hex_key) { /\A\h{128}\z/ }
    let(:rsa_key) { /\A-----BEGIN RSA PRIVATE KEY-----\n.+\n-----END RSA PRIVATE KEY-----\n\z/m }
    let(:alphanumeric_key) { /\A[A-Za-z0-9]{32}\z/m }

    around do |example|
      # We store Rails.application.credentials as a hash so that we can revert to the original
      # values after the example has run. Assigning Rails.application.credentials= directly doesn't work.
      original_credentials = Rails.application.credentials.to_h

      # Ensure we clear any existing `encrypted_settings_key_base` credential
      allowed_keys.each do |key|
        Rails.application.credentials.public_send(:"#{key}=", nil)
      end

      example.run

      original_credentials.each do |key, value|
        Rails.application.credentials.public_send(:"#{key}=", value)
      end
    end

    before do
      allow(File).to receive(:write).with(fake_secret_file.path, any_args)
    end

    context 'when none of the secrets exist' do
      before do
        stub_env('SECRET_KEY_BASE', nil)
      end

      it 'generates different hashes for secret_key_base, otp_key_base, and db_key_base' do
        initializer.execute!

        keys = Rails.application.credentials.values_at(:secret_key_base, :otp_key_base, :db_key_base)

        expect(keys.uniq).to eq(keys)
        expect(keys).to all(match(hex_key))
      end

      it 'generates an RSA key for openid_connect_signing_key' do
        initializer.execute!

        keys = Rails.application.credentials.values_at(:openid_connect_signing_key)

        expect(keys.uniq).to eq(keys)
        expect(keys).to all(match(rsa_key))
      end

      it 'generates alphanumeric keys for active_record_encryption items' do
        initializer.execute!

        expect(Rails.application.credentials.active_record_encryption_primary_key).to all(match(alphanumeric_key))
        expect(Rails.application.credentials.active_record_encryption_deterministic_key).to all(match(alphanumeric_key))
        expect(Rails.application.credentials.active_record_encryption_key_derivation_salt).to match(alphanumeric_key)
      end

      it 'warns about the secrets to add to secrets.yml' do
        allowed_keys.each do |key|
          expect(initializer).to receive(:warn_missing_secret).with(key.to_sym)
        end

        initializer.execute!
      end

      it 'writes the secrets to secrets.yml' do
        expect(File).to receive(:write).with(fake_secret_file.path, any_args) do |_filename, contents, _options|
          new_secrets = YAML.safe_load(contents)[rails_env_name]

          allowed_keys.each do |key|
            expect(new_secrets[key]).to eq(Rails.application.credentials.values_at(key.to_sym).first)
          end
          expect(new_secrets['encrypted_settings_key_base']).to be_nil # encrypted_settings_key_base is optional
        end

        initializer.execute!
      end

      context 'when GITLAB_GENERATE_ENCRYPTED_SETTINGS_KEY_BASE is set' do
        let(:allowed_keys) do
          super() + ['encrypted_settings_key_base']
        end

        before do
          stub_env('GITLAB_GENERATE_ENCRYPTED_SETTINGS_KEY_BASE', '1')
          allow(initializer).to receive(:warn_missing_secret)
        end

        it 'writes the encrypted_settings_key_base secret' do
          expect(initializer).to receive(:warn_missing_secret).with(:encrypted_settings_key_base)
          expect(File).to receive(:write).with(fake_secret_file.path, any_args) do |_filename, contents, _options|
            new_secrets = YAML.safe_load(contents)[rails_env_name]

            expect(new_secrets['encrypted_settings_key_base']).to eq(Rails.application.credentials.encrypted_settings_key_base)
          end

          initializer.execute!
        end
      end
    end

    shared_examples 'credentials are properly set' do
      it 'sets Rails.application.credentials' do
        initializer.execute!

        expect(Rails.application.credentials.values_at(*allowed_keys.map(&:to_sym))).to eq(allowed_keys)
      end

      it 'does not issue warnings' do
        expect(initializer).not_to receive(:warn_missing_secret)

        initializer.execute!
      end

      it 'does not update secrets.yml' do
        expect(File).not_to receive(:write)

        initializer.execute!
      end
    end

    context 'when secrets exist in secrets.yml' do
      let(:secrets_hash) { { rails_env_name => Hash[allowed_keys.zip(allowed_keys)] } }

      it_behaves_like 'credentials are properly set'

      context 'when secret_key_base also exist in the environment variable' do
        before do
          stub_env('SECRET_KEY_BASE', 'env_key')
        end

        it 'sets Rails.application.credentials.secret_key_base from the environment variable' do
          initializer.execute!

          expect(Rails.application.credentials.secret_key_base).to eq('env_key')
        end
      end
    end

    context 'when secrets exist in Rails.application.credentials' do
      before do
        allowed_keys.each do |key|
          Rails.application.credentials.public_send(:"#{key}=", key)
        end
      end

      it_behaves_like 'credentials are properly set'

      context 'when secret_key_base also exist in the environment variable' do
        before do
          stub_env('SECRET_KEY_BASE', 'env_key')
        end

        it 'sets Rails.application.credentials.secret_key_base from the environment variable' do
          initializer.execute!

          expect(Rails.application.credentials.secret_key_base).to eq('env_key')
        end
      end
    end

    context 'with some secrets missing, some in ENV, some in Rails.application.credentials, some in secrets.yml' do
      let(:rails_env_name) { 'foo' }
      let(:secrets_hash) do
        {
          rails_env_name => {
            'otp_key_base' => 'otp_key_base',
            'active_record_encryption_primary_key' => ['primary_key'],
            'active_record_encryption_deterministic_key' => ['deterministic_key'],
            'active_record_encryption_key_derivation_salt' => 'key_derivation_salt'
          }
        }
      end

      before do
        stub_env('SECRET_KEY_BASE', 'env_key')
        Rails.application.credentials.db_key_base = 'db_key_base'
      end

      it 'sets Rails.application.credentials properly, issue a warning and writes config.secrets.yml' do
        expect(File).to receive(:write).with(fake_secret_file.path, any_args) do |_filename, contents, _options|
          new_secrets = YAML.safe_load(contents)[rails_env_name]

          expect(new_secrets['otp_key_base']).to eq('otp_key_base')
          expect(new_secrets['openid_connect_signing_key']).to match(rsa_key)
        end
        expect(initializer).to receive(:warn).with(/^Creating a backup of secrets file/)
        expect(initializer).to receive(:warn).with(
          "Missing Rails.application.credentials.openid_connect_signing_key for #{rails_env_name} environment. " \
            "The secret will be generated and stored in config/secrets.yml."
        )

        expect(FileUtils).to receive(:mv).with(fake_secret_file.path, anything)
        initializer.execute!

        expect(Rails.application.credentials.secret_key_base).to eq('env_key')
        expect(Rails.application.credentials.db_key_base).to eq('db_key_base')
        expect(Rails.application.credentials.otp_key_base).to eq('otp_key_base')
      end
    end
  end
end
# rubocop:enable RSpec/FeatureCategory
# rubocop:enable RSpec/SpecFilePathFormat
