# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EncryptedAttribute, feature_category: :system_access do
  include DbKeyBaseHelpers

  %i[db_key_base db_key_base_32 db_key_base_truncated].each do |key_method|
    describe "##{key_method}" do
      let(:test_class) do
        Class.new(ApplicationRecord) do
          include Gitlab::EncryptedAttribute

          self.table_name = :projects

          attr_encrypted :token, key: key_method

          def self.name
            'Project'
          end
        end
      end

      let(:record) { test_class.new }

      describe key_method do
        context 'when encrypting' do
          before do
            record.attr_encrypted_encrypted_attributes[:token][:operation] = :encrypting
          end

          it 'returns the encryption key secret' do
            expect(record.__send__(key_method))
              .to eq(Gitlab::Encryption::KeyProvider[key_method].encryption_key.secret)
          end
        end

        context 'when decrypting' do
          before do
            record.attr_encrypted_encrypted_attributes[:token][:operation] = :decrypting
          end

          it 'returns the encryption key secret' do
            expect(record.__send__(key_method))
              .to eq(Gitlab::Encryption::KeyProvider[key_method].encryption_key.secret)
          end
        end
      end
    end
  end

  describe 'decryption with multiple db_key_base keys' do
    # Created with the real key so that other encrypted tokens stay readable
    let_it_be(:project) { create(:project) }

    let(:old_key) { Settings.db_key_base_keys.last }
    let(:new_key) { SecureRandom.hex(64) }

    shared_examples 'decrypts with every key' do |record_class_name, attribute|
      let(:record_class) { record_class_name.constantize }

      context 'with a single key' do
        it 'decrypts once with the current key' do
          record = record_class.find(create_with_key(old_key) { create_record }.id)

          expect(count_decrypts(record_class) { expect(record.public_send(attribute)).to eq(value) }).to eq(1)
          expect(record.attr_encrypted_encrypted_with(attribute)).to eq(:current)
        end
      end

      context 'when the value was encrypted with the old key' do
        let!(:record) { create_with_key(old_key) { create_record } }

        before do
          stub_db_key_base_keys(old_key, new_key)
        end

        it 'decrypts it and reports the previous key' do
          reloaded = record_class.find(record.id)

          expect(reloaded.public_send(attribute)).to eq(value)
          expect(reloaded.attr_encrypted_encrypted_with(attribute)).to eq(:previous)
        end
      end

      context 'when the value was encrypted with the new key' do
        before do
          stub_db_key_base_keys(old_key, new_key)
        end

        it 'decrypts it and reports the current key' do
          reloaded = record_class.find(create_record.id)

          expect(reloaded.public_send(attribute)).to eq(value)
          expect(reloaded.attr_encrypted_encrypted_with(attribute)).to eq(:current)
        end
      end
    end

    context 'with an attribute that does not use a db_key_base key' do
      let(:test_class) do
        Class.new(ApplicationRecord) do
          include Gitlab::EncryptedAttribute

          self.table_name = :projects

          attr_accessor :encrypted_token, :encrypted_token_iv

          attr_encrypted :token, key: 'a' * 32

          def self.name
            'Project'
          end
        end
      end

      it 'decrypts once with its own key' do
        record = test_class.new(token: 'secret')
        stub_db_key_base_keys(old_key, new_key)

        expect(count_decrypts(test_class) do
          expect(record.attr_encrypted_decrypt(:token, record.encrypted_token)).to eq('secret')
        end).to eq(1)
      end
    end

    context 'with an aes-256-gcm attribute' do
      let(:value) { 'https://example.com/hook' }

      def create_record
        create(:project_hook, project: project, url: value)
      end

      it_behaves_like 'decrypts with every key', 'ProjectHook', :url

      it 'raises once the old key is removed' do
        record = create_with_key(old_key) { create_record }
        stub_db_key_base_keys(new_key)

        expect { ProjectHook.find(record.id).url }.to raise_error(OpenSSL::Cipher::CipherError)
      end

      it 'tries the current key first' do
        stub_db_key_base_keys(old_key, new_key)
        record = ProjectHook.find(create_record.id)

        expect(count_decrypts(ProjectHook) { record.url }).to eq(1)
      end
    end

    context 'with a marshaled aes-256-gcm attribute' do
      let(:value) { { 'foo' => 'bar' } }

      def create_record
        create(:project_hook, project: project, url: 'https://example.com/{foo}', url_variables: value)
      end

      it_behaves_like 'decrypts with every key', 'ProjectHook', :url_variables
    end

    context 'with an aes-256-cbc attribute' do
      let(:value) { 'secret-value' }

      def create_record
        create(:ci_variable, project: project, value: value)
      end

      it_behaves_like 'decrypts with every key', 'Ci::Variable', :value

      it 'reports no key for an empty value' do
        stub_db_key_base_keys(old_key, new_key)

        expect(Ci::Variable.new.attr_encrypted_encrypted_with(:value)).to be_nil
      end

      context 'when rotating' do
        let!(:record) { Ci::Variable.find(create_with_key(old_key) { create_record }.id) }

        before do
          stub_db_key_base_keys(old_key, new_key)
        end

        it 'tries every key' do
          expect(count_decrypts(Ci::Variable) { record.value }).to eq(2)
        end

        it 'ignores a wrong key that returns an invalid string' do
          allow(Ci::Variable).to receive(:attr_encrypted_decrypt).and_wrap_original do |method, *args|
            args.last[:key] == new_key ? (+"\xFF\xFE").force_encoding('UTF-8') : method.call(*args)
          end

          expect(record.value).to eq(value)
          expect(record.attr_encrypted_encrypted_with(:value)).to eq(:previous)
        end

        it 'accepts a value that only one key decrypts, even when it is not valid UTF-8' do
          invalid = (+"\xFF\xFE").force_encoding('UTF-8')
          allow(Ci::Variable).to receive(:attr_encrypted_decrypt).and_wrap_original do |method, *args|
            raise OpenSSL::Cipher::CipherError, 'bad decrypt' if args.last[:key] == new_key

            method.call(*args)
            invalid
          end

          expect(record.value).to eq(invalid)
        end

        it 'tries the next key when a wrong key makes the load raise an unexpected error' do
          allow(Ci::Variable).to receive(:attr_encrypted_decrypt).and_wrap_original do |method, *args|
            raise NoMethodError, 'garbage' if args.last[:key] == new_key

            method.call(*args)
          end

          expect(record.value).to eq(value)
        end

        it 'raises when more than one key gives a plausible value' do
          allow(Ci::Variable).to receive(:attr_encrypted_decrypt) { |*args| "plausible-#{args.last[:key]}" }

          expect { record.value }.to raise_error(described_class::AmbiguousDecryptionError, /Ci::Variable#value/)
        end

        it 'raises when every key gives an invalid string' do
          allow(Ci::Variable).to receive(:attr_encrypted_decrypt) do |*args|
            "\xFF#{args.last[:key] == new_key ? "\xFE" : "\xFD"}".force_encoding('UTF-8')
          end

          expect { record.value }.to raise_error(OpenSSL::Cipher::CipherError)
        end

        it 'accepts identical values from identical keys' do
          stub_db_key_base_keys(old_key, old_key)

          expect(record.value).to eq(value)
          expect(record.attr_encrypted_encrypted_with(:value)).to eq(:current)
        end

        it 'accepts identical values from identical keys, even when they are not valid UTF-8' do
          stub_db_key_base_keys(old_key, old_key)
          invalid = (+"\xFF\xFE").force_encoding('UTF-8')
          allow(Ci::Variable).to receive(:attr_encrypted_decrypt).and_return(invalid)

          expect(record.value).to eq(invalid)
        end

        it 'raises when no key decrypts the value' do
          stub_db_key_base_keys(SecureRandom.hex(64), new_key)

          expect { record.value }.to raise_error(OpenSSL::Cipher::CipherError)
        end
      end
    end

    context 'with a marshaled aes-256-cbc attribute' do
      let(:value) { { user: 'user', password: 'password' } }

      def create_record
        create(:remote_mirror, project: project, url: 'https://user:password@example.com/repo.git')
      end

      it_behaves_like 'decrypts with every key', 'RemoteMirror', :credentials
    end

    # On update, before_validation callbacks decrypt the previous URL and URL variables
    # to reset URL variables and custom headers when the URL changes. That decryption
    # must work during rotation.
    context 'when a hook written with the old key is updated' do
      let!(:hook) do
        create_with_key(old_key) do
          create(:project_hook, project: project, url: 'https://example.com/hook',
            url_variables: { 'abc' => 'foo' }, custom_headers: { 'X-Foo' => 'bar' })
        end
      end

      before do
        stub_db_key_base_keys(old_key, new_key)
      end

      it 'keeps URL variables and custom headers when the URL is unchanged' do
        ProjectHook.find(hook.id).update!(url: 'https://example.com/hook')

        hook.reload
        expect(hook.url_variables).to eq({ 'abc' => 'foo' })
        expect(hook.custom_headers).to eq({ 'X-Foo' => 'bar' })
      end

      it 'resets URL variables and custom headers when the URL changes' do
        ProjectHook.find(hook.id).update!(url: 'https://example.com/other')

        hook.reload
        expect(hook.url_variables).to eq({})
        expect(hook.custom_headers).to eq({})
      end
    end

    context 'when the attr_encrypted_multi_key_decrypt feature flag is disabled' do
      let!(:hook) do
        create_with_key(old_key) do
          create(:project_hook, project: project, url: 'https://example.com/hook',
            url_variables: { 'abc' => 'foo' }, custom_headers: { 'X-Foo' => 'bar' })
        end
      end

      before do
        stub_feature_flags(attr_encrypted_multi_key_decrypt: false)
      end

      it 'decrypts once with the current key' do
        record = ProjectHook.find(hook.id)

        expect(count_decrypts(ProjectHook) { expect(record.url).to eq('https://example.com/hook') }).to eq(1)
      end

      it 'does not decrypt with a previous key' do
        stub_db_key_base_keys(old_key, new_key)

        expect { ProjectHook.find(hook.id).url }.to raise_error(OpenSSL::Cipher::CipherError)
      end

      it 'decrypts the previous URL and URL variables on update' do
        ProjectHook.find(hook.id).update!(url: 'https://example.com/other')

        hook.reload
        expect(hook.url_variables).to eq({})
        expect(hook.custom_headers).to eq({})
      end
    end
  end
end
