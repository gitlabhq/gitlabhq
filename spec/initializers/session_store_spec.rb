# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session initializer for GitLab' do
  subject { Gitlab::Application.config }

  before do
    allow(subject).to receive_message_chain(:middleware, :insert_after)
  end

  let(:load_session_store) do
    load Rails.root.join('config/initializers/session_store.rb')
  end

  describe 'config#session_store' do
    it 'initialized as a redis_store with Gitlab::Sessions::CacheStore' do
      expect(subject).to receive(:session_store).with(
        ::Gitlab::Sessions::CacheStore,
        a_hash_including(
          cache: ActiveSupport::Cache::RedisCacheStore
        )
      )

      load_session_store
    end

    context 'when cell is enabled' do
      before do
        stub_config(cell: { enabled: true, id: 1 })
      end

      it 'initialized as a `redis_store` with session cookies prefix that includes cell id' do
        expect(subject).to receive(:session_store).with(
          ::Gitlab::Sessions::CacheStore,
          a_hash_including(
            cache: ActiveSupport::Cache::RedisCacheStore,
            session_cookie_token_prefix: 'cell-1'
          )
        )

        load_session_store
      end

      context 'and session_cookie_token_prefix is pre-set' do
        let(:config_path) { Rails.root.join('config/session_store.yml') }
        let(:test_config) { { session_cookie_token_prefix: session_cookie_token_prefix } }

        before do
          stub_config(cell: { enabled: true, id: 3 })
          allow(File).to receive(:exist?).with(config_path).and_return(true)
          allow(Rails.application).to receive(:config_for).with(:session_store).and_return(test_config)
        end

        context 'when it does not align with the required format' do
          let(:session_cookie_token_prefix) { 'custom-value' }

          it 'raises an exception' do
            message = 'Given that cells are enabled, the session_cookie_token_prefix must be left blank or ' \
              "specifically set to 'cell-3'. Currently it is set to: '#{session_cookie_token_prefix}'."
            expect { load_session_store }.to raise_error(RuntimeError, message)
          end
        end

        context 'when it aligns with the required format' do
          let(:session_cookie_token_prefix) { 'cell-3' }

          it 'loads gracefully' do
            expect(subject).to receive(:session_store).with(
              ::Gitlab::Sessions::CacheStore,
              a_hash_including(
                cache: ActiveSupport::Cache::RedisCacheStore,
                session_cookie_token_prefix: session_cookie_token_prefix
              )
            )

            expect { load_session_store }.not_to raise_error
          end
        end
      end
    end

    context 'when cell is disabled' do
      before do
        stub_config(cell: { enabled: false })
      end

      it 'initialized as a `redis_store` with empty session cookie prefix' do
        expect(subject).to receive(:session_store).with(
          ::Gitlab::Sessions::CacheStore,
          a_hash_including(
            cache: ActiveSupport::Cache::RedisCacheStore,
            session_cookie_token_prefix: ''
          )
        )

        load_session_store
      end

      context 'and session_cookie_token_prefix is pre-set' do
        let(:config_path) { Rails.root.join('config/session_store.yml') }
        let(:test_config) { { session_cookie_token_prefix: session_cookie_token_prefix } }

        before do
          stub_config(cell: { enabled: false, id: 3 })
          allow(File).to receive(:exist?).with(config_path).and_return(true)
          allow(Rails.application).to receive(:config_for).with(:session_store).and_return(test_config)
        end

        context 'when it does not align with the required format' do
          let(:session_cookie_token_prefix) { 'custom-value' }

          it 'loads gracefully' do
            expect(subject).to receive(:session_store).with(
              ::Gitlab::Sessions::CacheStore,
              a_hash_including(
                cache: ActiveSupport::Cache::RedisCacheStore,
                session_cookie_token_prefix: session_cookie_token_prefix
              )
            )

            expect { load_session_store }.not_to raise_error
          end
        end

        context 'when it aligns with the required format' do
          let(:session_cookie_token_prefix) { 'cell-3' }

          it 'loads gracefully' do
            expect(subject).to receive(:session_store).with(
              ::Gitlab::Sessions::CacheStore,
              a_hash_including(
                cache: ActiveSupport::Cache::RedisCacheStore,
                session_cookie_token_prefix: session_cookie_token_prefix
              )
            )

            expect { load_session_store }.not_to raise_error
          end
        end
      end
    end
  end

  describe 'cookie salt settings' do
    context 'with default settings' do
      it 'sets signed_cookie_salt and authenticated_encrypted_cookie_salt to default value' do
        load_session_store
        expect(subject.action_dispatch.signed_cookie_salt).to eql('signed cookie')
        expect(subject.action_dispatch.authenticated_encrypted_cookie_salt).to eql('authenticated encrypted cookie')
      end
    end

    context 'with custom settings' do
      before do
        allow(Settings).to receive(:[]).with('gitlab').and_return({
          'signed_cookie_salt' => 'custom signed salt',
          'authenticated_encrypted_cookie_salt' => 'custom encrypted salt'
        })
      end

      it 'sets signed_cookie_salt and authenticated_encrypted_cookie_salt to custom values' do
        load_session_store
        expect(subject.action_dispatch.signed_cookie_salt).to eql('custom signed salt')
        expect(subject.action_dispatch.authenticated_encrypted_cookie_salt).to eql('custom encrypted salt')
      end
    end
  end
end
