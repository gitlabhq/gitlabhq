# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::UserFromMention, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:project_id) { 11 }
  let(:importer) { 'bitbucket_server' }
  let(:cache_key) { "#{importer}/project/#{project_id}/source/#{source_key}" }

  let(:example) do
    Class.new do
      include Gitlab::Import::UserFromMention

      def initialize(importer, project_id)
        @importer = importer
        @project_id = project_id
      end

      attr_reader :project_id, :importer

      def get_user_from_cache(mention)
        user_from_cache(mention)
      end

      def set_users_in_cache(hash)
        cache_multiple(hash)
      end
    end
  end

  subject(:example_class) { example.new(importer, project_id) }

  describe '#user_from_cache' do
    context 'when the cache_key is a cache miss' do
      let(:source_key) { '{1111:11-11}' }
      let(:cache_value) { { value: 'Jane Doe', type: :name }.to_json }

      before do
        ::Gitlab::Cache::Import::Caching.write(cache_key, cache_value)
      end

      it 'returns nil if the mention is a cache miss' do
        expect(example_class.get_user_from_cache('{2222:22-22}')).to be_nil
      end
    end

    context 'when the cache_key is a cache hit' do
      context 'and the cached value can be mapped to a user record' do
        let(:source_key) { 'janedoe' }
        let(:email) { 'jane@gmail.com' }
        let(:cache_value) { { value: email, type: :email }.to_json }

        before do
          ::Gitlab::Cache::Import::Caching.write(cache_key, cache_value)
        end

        context 'if a user with the email does not exist' do
          it 'returns nil' do
            expect(example_class.get_user_from_cache(source_key)).to be_nil
          end
        end

        context 'if a user with the email exists' do
          let!(:user) { create(:user, email: email) }

          it 'returns the user' do
            expect(example_class.get_user_from_cache(source_key)).to eq(user)
          end
        end

        context 'if a user with the same username exists but email does not match' do
          let!(:user) { create(:user, username: source_key, email: 'jane_doe-smith@gmail.com') }

          it 'returns nil' do
            expect(example_class.get_user_from_cache(source_key)).to be_nil
          end
        end
      end

      context 'and the cached value can not be mapped to a user record' do
        let(:source_key) { 'janedoe' }
        let(:name) { 'Jane Doe' }
        let(:cache_value) { { value: name, type: :name }.to_json }

        before do
          ::Gitlab::Cache::Import::Caching.write(cache_key, cache_value)
        end

        it 'returns the cached value' do
          expect(example_class.get_user_from_cache(source_key)).to eq(name)
        end

        it 'does not attempt to find a user record' do
          expect(User).not_to receive(:find_by_any_email)
        end
      end
    end

    context 'when the cache_key was a miss but a hit for old username specific key' do
      context 'and the cached value can be mapped to a user record' do
        let(:username) { 'janedoe' }
        let(:email) { 'jane@gmail.com' }
        let(:cache_key) { "#{importer}/project/#{project_id}/source/username/#{username}" }
        let(:cache_value) { email }

        before do
          ::Gitlab::Cache::Import::Caching.write(cache_key, cache_value)
        end

        context 'if a user with the email does not exist' do
          it 'returns nil' do
            expect(example_class.get_user_from_cache(username)).to be_nil
          end
        end

        context 'if a user with the email exists' do
          let!(:user) { create(:user, email: email) }

          it 'returns the user' do
            expect(example_class.get_user_from_cache(username)).to eq(user)
          end
        end

        context 'if a user with the same username exists but email does not match' do
          let!(:user) { create(:user, username: username, email: 'jane_doe-smith@gmail.com') }

          it 'returns nil' do
            expect(example_class.get_user_from_cache(username)).to be_nil
          end
        end
      end
    end
  end

  describe '#cache_multiple' do
    let(:hash) { { key: 'value' } }

    it 'calls write_multiple with the hash' do
      expect(Gitlab::Cache::Import::Caching).to receive(:write_multiple).with(hash, timeout: 72.hours)

      example_class.set_users_in_cache(hash)
    end
  end

  describe '#source_user_cache_key' do
    let(:source_key) { 'janedoe' }

    it 'creates a cache key for the given importer, project_id, and source_key' do
      expect(example_class.source_user_cache_key(importer, project_id, source_key)).to eq(cache_key)
    end
  end

  describe '#source_user_cache_value' do
    let(:email) { 'jane@gmail.com' }

    it 'creates a json string to store a potentially user-mappable value and what type of value it is' do
      expect(example_class.source_user_cache_value(email, type: :email)).to eq({ value: email, type: :email }.to_json)
    end
  end
end
