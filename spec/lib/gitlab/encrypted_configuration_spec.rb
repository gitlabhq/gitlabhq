# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::EncryptedConfiguration do
  subject(:configuration) { described_class.new }

  let!(:config_tmp_dir) { Dir.mktmpdir('config-') }

  after do
    FileUtils.rm_f(config_tmp_dir)
  end

  describe '#initialize' do
    it 'accepts all args as optional fields' do
      expect { configuration }.not_to raise_exception

      expect(configuration.key).to be_nil
      expect(configuration.previous_keys).to be_empty
    end

    it 'generates 32 byte key when provided a larger base key' do
      configuration = described_class.new(base_key: 'A' * 64)

      expect(configuration.key.bytesize).to eq 32
    end

    it 'generates 32 byte key when provided a smaller base key' do
      configuration = described_class.new(base_key: 'A' * 16)

      expect(configuration.key.bytesize).to eq 32
    end

    it 'throws an error when the base key is too small' do
      expect { described_class.new(base_key: 'A' * 12) }.to raise_error 'Base key too small'
    end
  end

  context 'when provided a config file but no key' do
    let(:config_path) { File.join(config_tmp_dir, 'credentials.yml.enc') }

    it 'throws an error when writing without a key' do
      expect { described_class.new(content_path: config_path).write('test') }.to raise_error Gitlab::EncryptedConfiguration::MissingKeyError
    end

    it 'throws an error when reading without a key' do
      config = described_class.new(content_path: config_path)
      File.write(config_path, 'test')
      expect { config.read }.to raise_error Gitlab::EncryptedConfiguration::MissingKeyError
    end
  end

  context 'when provided key and config file' do
    let(:credentials_config_path) { File.join(config_tmp_dir, 'credentials.yml.enc') }
    let(:credentials_key) { SecureRandom.hex(64) }

    describe '#write' do
      it 'encrypts the file using the provided key' do
        encryptor = ActiveSupport::MessageEncryptor.new(described_class.generate_key(credentials_key), cipher: 'aes-256-gcm')
        config = described_class.new(content_path: credentials_config_path, base_key: credentials_key)

        config.write('sample-content')
        expect(encryptor.decrypt_and_verify(File.read(credentials_config_path))).to eq('sample-content')
      end
    end

    describe '#read' do
      it 'reads yaml configuration' do
        config = described_class.new(content_path: credentials_config_path, base_key: credentials_key)

        config.write({ foo: { bar: true } }.to_yaml)
        expect(config[:foo][:bar]).to be true
      end

      it 'allows referencing top level keys via dot syntax' do
        config = described_class.new(content_path: credentials_config_path, base_key: credentials_key)

        config.write({ foo: { bar: true } }.to_yaml)
        expect(config.foo[:bar]).to be true
      end

      it 'throws a custom error when referencing an invalid key map config' do
        config = described_class.new(content_path: credentials_config_path, base_key: credentials_key)

        config.write("stringcontent")
        expect { config[:foo] }.to raise_error Gitlab::EncryptedConfiguration::InvalidConfigError
      end
    end

    describe '#change' do
      it 'changes yaml configuration' do
        config = described_class.new(content_path: credentials_config_path, base_key: credentials_key)

        config.write({ foo: { bar: true } }.to_yaml)
        config.change do |unencrypted_contents|
          contents = YAML.safe_load(unencrypted_contents, permitted_classes: [Symbol])
          contents.merge(beef: "stew").to_yaml
        end
        expect(config.foo[:bar]).to be true
        expect(config.beef).to eq('stew')
      end
    end

    context 'when provided previous_keys for rotation' do
      let(:credential_key_original) { SecureRandom.hex(64) }
      let(:credential_key_latest) { SecureRandom.hex(64) }
      let(:config_path_original) { File.join(config_tmp_dir, 'credentials-orig.yml.enc') }
      let(:config_path_latest) { File.join(config_tmp_dir, 'credentials-latest.yml.enc') }

      def encryptor(key)
        ActiveSupport::MessageEncryptor.new(Gitlab::EncryptedConfiguration.generate_key(key), cipher: 'aes-256-gcm')
      end

      describe '#write' do
        it 'rotates the key when provided a new key' do
          config1 = described_class.new(content_path: config_path_original, base_key: credential_key_original)
          config1.write('sample-content1')

          config2 = described_class.new(content_path: config_path_latest, base_key: credential_key_latest, previous_keys: [credential_key_original])
          config2.write('sample-content2')

          original_key_encryptor = encryptor(credential_key_original) # can read with the initial key
          latest_key_encryptor = encryptor(credential_key_latest) # can read with the new key
          both_key_encryptor = encryptor(credential_key_latest) # can read with either key
          both_key_encryptor.rotate(described_class.generate_key(credential_key_original))

          expect(original_key_encryptor.decrypt_and_verify(File.read(config_path_original))).to eq('sample-content1')
          expect(both_key_encryptor.decrypt_and_verify(File.read(config_path_original))).to eq('sample-content1')
          expect(latest_key_encryptor.decrypt_and_verify(File.read(config_path_latest))).to eq('sample-content2')
          expect(both_key_encryptor.decrypt_and_verify(File.read(config_path_latest))).to eq('sample-content2')
          expect { original_key_encryptor.decrypt_and_verify(File.read(config_path_latest)) }.to raise_error(ActiveSupport::MessageEncryptor::InvalidMessage)
        end
      end

      describe '#read' do
        it 'supports reading using rotated config' do
          described_class.new(content_path: config_path_original, base_key: credential_key_original).write({ foo: { bar: true } }.to_yaml)

          config = described_class.new(content_path: config_path_original, base_key: credential_key_latest,  previous_keys: [credential_key_original])
          expect(config[:foo][:bar]).to be true
        end
      end
    end
  end
end
