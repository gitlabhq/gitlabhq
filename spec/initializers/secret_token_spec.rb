require 'spec_helper'
require_relative '../../config/initializers/secret_token'

describe 'create_tokens', lib: true do
  let(:config) { ActiveSupport::OrderedOptions.new }
  let(:secrets) { ActiveSupport::OrderedOptions.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(File).to receive(:write)
    allow(Rails).to receive_message_chain(:application, :config).and_return(config)
    allow(Rails).to receive_message_chain(:application, :secrets).and_return(secrets)
    allow(Rails).to receive_message_chain(:root, :join) { |string| string }
  end

  context 'setting otp_key_base' do
    context 'when none of the secrets exist' do
      before do
        allow(ENV).to receive(:[]).with('SECRET_KEY_BASE').and_return(nil)
        allow(File).to receive(:exist?).with('.secret').and_return(false)
        allow(File).to receive(:exist?).with('config/secrets.yml').and_return(false)
        allow(File).to receive(:write)
        allow(self).to receive(:warn_missing_secret)
      end

      it 'generates different secrets for secret_key_base, otp_key_base, and db_key_base' do
        create_tokens

        keys = [config.secret_key_base, secrets.otp_key_base, secrets.db_key_base]

        expect(keys.uniq).to eq(keys)
        expect(keys.map(&:length)).to all(eq(128))
      end

      it 'warns about the secrets to add to secrets.yml' do
        expect(self).to receive(:warn_missing_secret).with('otp_key_base')
        expect(self).to receive(:warn_missing_secret).with('db_key_base')

        create_tokens
      end

      it 'writes the secrets to secrets.yml' do
        expect(File).to receive(:write).with('config/secrets.yml', any_args) do |filename, contents, options|
          new_secrets_yml = YAML.load(contents)

          expect(new_secrets_yml['test']['otp_key_base']).to eq(secrets.otp_key_base)
          expect(new_secrets_yml['test']['db_key_base']).to eq(secrets.db_key_base)
        end

        create_tokens
      end

      it 'writes the secret_key_base to .secret' do
        secret_key_base = nil

        expect(File).to receive(:write).with('.secret', any_args) do |filename, contents|
          secret_key_base = contents
        end

        create_tokens

        expect(secret_key_base).to eq(config.secret_key_base)
      end
    end

    context 'when the other secrets all exist' do
      before do
        secrets.db_key_base = 'db_key_base'

        allow(ENV).to receive(:[]).with('SECRET_KEY_BASE').and_return('env_key')
        allow(File).to receive(:exist?).with('.secret').and_return(true)
        allow(File).to receive(:read).with('.secret').and_return('file_key')
      end

      context 'when the otp_key_base secret exists' do
        before { secrets.otp_key_base = 'otp_key_base' }

        it 'does not write any files' do
          expect(File).not_to receive(:write)

          create_tokens
        end

        it 'does not generate any new keys' do
          expect(SecureRandom).not_to receive(:hex)

          create_tokens
        end

        it 'sets the the keys to the values from the environment and secrets.yml' do
          create_tokens

          expect(config.secret_key_base).to eq('env_key')
          expect(secrets.otp_key_base).to eq('otp_key_base')
          expect(secrets.db_key_base).to eq('db_key_base')
        end
      end

      context 'when the otp_key_base secret does not exist' do
        before do
          allow(File).to receive(:exist?).with('config/secrets.yml').and_return(true)
          allow(YAML).to receive(:load_file).with('config/secrets.yml').and_return('test' => secrets.to_h.stringify_keys)
          allow(self).to receive(:warn_missing_secret)
        end

        it 'uses the env secret' do
          expect(SecureRandom).not_to receive(:hex)
          expect(File).to receive(:write) do |filename, contents, options|
            new_secrets_yml = YAML.load(contents)

            expect(new_secrets_yml['test']['otp_key_base']).to eq('env_key')
            expect(new_secrets_yml['test']['db_key_base']).to eq('db_key_base')
          end

          create_tokens

          expect(secrets.otp_key_base).to eq('env_key')
        end

        it 'keeps the other secrets as they were' do
          create_tokens

          expect(config.secret_key_base).to eq('env_key')
          expect(secrets.db_key_base).to eq('db_key_base')
        end

        it 'warns about the missing secret' do
          expect(self).to receive(:warn_missing_secret).with('otp_key_base')

          create_tokens
        end
      end
    end
  end
end
