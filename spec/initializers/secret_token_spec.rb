# frozen_string_literal: true

require 'spec_helper'
require_relative '../../config/initializers/01_secret_token'

RSpec.describe 'create_tokens' do
  include StubENV

  let(:secrets) { ActiveSupport::OrderedOptions.new }
  let(:hex_key) { /\h{128}/.freeze }
  let(:rsa_key) { /\A-----BEGIN RSA PRIVATE KEY-----\n.+\n-----END RSA PRIVATE KEY-----\n\Z/m.freeze }

  before do
    allow(Rails).to receive_message_chain(:application, :secrets).and_return(secrets)
    allow(Rails).to receive_message_chain(:root, :join) { |string| string }

    allow(File).to receive(:write).and_call_original
    allow(File).to receive(:write).with(Rails.root.join('config/secrets.yml'))
    allow(File).to receive(:delete).and_call_original
    allow(File).to receive(:delete).with(Rails.root.join('.secret'))
    allow(self).to receive(:warn)
    allow(self).to receive(:exit)
  end

  describe 'ensure acknowledged secrets in any installations' do
    let(:acknowledged_secrets) do
      %w[secret_key_base otp_key_base db_key_base openid_connect_signing_key encrypted_settings_key_base rotated_encrypted_settings_key_base]
    end

    it 'does not allow to add a new secret without a proper handling' do
      create_tokens

      secrets_hash = YAML.load_file(Rails.root.join('config/secrets.yml'))

      secrets_hash.each do |environment, secrets|
        new_secrets = secrets.keys - acknowledged_secrets

        expect(new_secrets).to be_empty,
         <<~EOS
           CAUTION:
           It looks like you have just added new secret(s) #{new_secrets.inspect} to the secrets.yml.
           Please read the development guide for GitLab secrets at doc/development/application_secrets.md before you proceed this change.
           If you're absolutely sure that the change is safe, please add the new secrets to the 'acknowledged_secrets' in order to silence this warning.
         EOS
      end
    end
  end

  context 'setting secret keys' do
    context 'when none of the secrets exist' do
      before do
        stub_env('SECRET_KEY_BASE', nil)
        allow(File).to receive(:exist?).with('.secret').and_return(false)
        allow(File).to receive(:exist?).with('config/secrets.yml').and_return(false)
        allow(self).to receive(:warn_missing_secret)
      end

      it 'generates different hashes for secret_key_base, otp_key_base, and db_key_base' do
        create_tokens

        keys = secrets.values_at(:secret_key_base, :otp_key_base, :db_key_base)

        expect(keys.uniq).to eq(keys)
        expect(keys).to all(match(hex_key))
      end

      it 'generates an RSA key for openid_connect_signing_key' do
        create_tokens

        keys = secrets.values_at(:openid_connect_signing_key)

        expect(keys.uniq).to eq(keys)
        expect(keys).to all(match(rsa_key))
      end

      it 'warns about the secrets to add to secrets.yml' do
        expect(self).to receive(:warn_missing_secret).with('secret_key_base')
        expect(self).to receive(:warn_missing_secret).with('otp_key_base')
        expect(self).to receive(:warn_missing_secret).with('db_key_base')
        expect(self).to receive(:warn_missing_secret).with('openid_connect_signing_key')

        create_tokens
      end

      it 'writes the secrets to secrets.yml' do
        expect(File).to receive(:write).with('config/secrets.yml', any_args) do |filename, contents, options|
          new_secrets = YAML.safe_load(contents)[Rails.env]

          expect(new_secrets['secret_key_base']).to eq(secrets.secret_key_base)
          expect(new_secrets['otp_key_base']).to eq(secrets.otp_key_base)
          expect(new_secrets['db_key_base']).to eq(secrets.db_key_base)
          expect(new_secrets['openid_connect_signing_key']).to eq(secrets.openid_connect_signing_key)
          expect(new_secrets['encrypted_settings_key_base']).to eq(secrets.encrypted_settings_key_base)
        end

        create_tokens
      end

      it 'does not write a .secret file' do
        expect(File).not_to receive(:write).with('.secret')

        create_tokens
      end
    end

    context 'when the other secrets all exist' do
      before do
        secrets.db_key_base = 'db_key_base'
        secrets.openid_connect_signing_key = 'openid_connect_signing_key'
        secrets.encrypted_settings_key_base = 'encrypted_settings_key_base'

        allow(File).to receive(:exist?).with('.secret').and_return(true)
        stub_file_read('.secret', content: 'file_key')
      end

      context 'when secret_key_base exists in the environment and secrets.yml' do
        before do
          stub_env('SECRET_KEY_BASE', 'env_key')
          secrets.secret_key_base = 'secret_key_base'
          secrets.otp_key_base = 'otp_key_base'
          secrets.openid_connect_signing_key = 'openid_connect_signing_key'
        end

        it 'does not issue a warning' do
          expect(self).not_to receive(:warn)

          create_tokens
        end

        it 'uses the environment variable' do
          create_tokens

          expect(secrets.secret_key_base).to eq('env_key')
        end

        it 'does not update secrets.yml' do
          expect(File).not_to receive(:write)

          create_tokens
        end
      end

      context 'when secret_key_base and otp_key_base exist' do
        before do
          secrets.secret_key_base = 'secret_key_base'
          secrets.otp_key_base = 'otp_key_base'
          secrets.openid_connect_signing_key = 'openid_connect_signing_key'
        end

        it 'does not write any files' do
          expect(File).not_to receive(:write)

          create_tokens
        end

        it 'sets the keys to the values from the environment and secrets.yml' do
          create_tokens

          expect(secrets.secret_key_base).to eq('secret_key_base')
          expect(secrets.otp_key_base).to eq('otp_key_base')
          expect(secrets.db_key_base).to eq('db_key_base')
          expect(secrets.openid_connect_signing_key).to eq('openid_connect_signing_key')
          expect(secrets.encrypted_settings_key_base).to eq('encrypted_settings_key_base')
        end

        it 'deletes the .secret file' do
          expect(File).to receive(:delete).with('.secret')

          create_tokens
        end
      end

      context 'when secret_key_base and otp_key_base do not exist' do
        before do
          allow(File).to receive(:exist?).with('config/secrets.yml').and_return(true)
          allow(YAML).to receive(:load_file).with('config/secrets.yml').and_return('test' => secrets.to_h.stringify_keys)
          allow(self).to receive(:warn_missing_secret)
        end

        it 'uses the file secret' do
          expect(File).to receive(:write) do |filename, contents, options|
            new_secrets = YAML.safe_load(contents)[Rails.env]

            expect(new_secrets['secret_key_base']).to eq('file_key')
            expect(new_secrets['otp_key_base']).to eq('file_key')
            expect(new_secrets['db_key_base']).to eq('db_key_base')
            expect(new_secrets['openid_connect_signing_key']).to eq('openid_connect_signing_key')
          end

          create_tokens

          expect(secrets.otp_key_base).to eq('file_key')
        end

        it 'keeps the other secrets as they were' do
          create_tokens

          expect(secrets.db_key_base).to eq('db_key_base')
        end

        it 'warns about the missing secrets' do
          expect(self).to receive(:warn_missing_secret).with('secret_key_base')
          expect(self).to receive(:warn_missing_secret).with('otp_key_base')

          create_tokens
        end

        it 'deletes the .secret file' do
          expect(File).to receive(:delete).with('.secret')

          create_tokens
        end
      end

      context 'when rotated_encrypted_settings_key_base does not exist' do
        before do
          secrets.secret_key_base = 'secret_key_base'
          secrets.otp_key_base = 'otp_key_base'
          secrets.openid_connect_signing_key = 'openid_connect_signing_key'
          secrets.encrypted_settings_key_base = 'encrypted_settings_key_base'
        end

        it 'does not warn about the missing secrets' do
          expect(self).not_to receive(:warn_missing_secret).with('rotated_encrypted_settings_key_base')

          create_tokens
        end

        it 'does not update secrets.yml' do
          expect(File).not_to receive(:write)

          create_tokens
        end
      end
    end

    context 'when db_key_base is blank but exists in secrets.yml' do
      before do
        secrets.otp_key_base = 'otp_key_base'
        secrets.secret_key_base = 'secret_key_base'
        secrets.encrypted_settings_key_base = 'encrypted_settings_key_base'
        yaml_secrets = secrets.to_h.stringify_keys.merge('db_key_base' => '<%= an_erb_expression %>')

        allow(File).to receive(:exist?).with('.secret').and_return(false)
        allow(File).to receive(:exist?).with('config/secrets.yml').and_return(true)
        allow(YAML).to receive(:load_file).with('config/secrets.yml').and_return('test' => yaml_secrets)
        allow(self).to receive(:warn_missing_secret)
      end

      it 'warns about updating db_key_base' do
        expect(self).to receive(:warn_missing_secret).with('db_key_base')

        create_tokens
      end

      it 'warns about the blank value existing in secrets.yml and exits' do
        expect(self).to receive(:warn) do |warning|
          expect(warning).to include('db_key_base')
          expect(warning).to include('<%= an_erb_expression %>')
        end

        create_tokens
      end

      it 'does not update secrets.yml' do
        expect(self).to receive(:exit).with(1).and_call_original
        expect(File).not_to receive(:write)

        expect { create_tokens }.to raise_error(SystemExit)
      end
    end
  end
end
