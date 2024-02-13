# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::UserFromMention, :clean_gitlab_redis_cache, feature_category: :importers do
  let(:project_id) { 11 }
  let(:username) { '@johndoe' }
  let(:email) { 'john@gmail.com' }
  let(:hash) { { key: 'value' } }
  let(:importer) { 'bitbucket_server' }
  let(:cache_key) { "#{importer}/project/#{project_id}/source/username/#{username}" }

  let(:example) do
    Class.new do
      include Gitlab::Import::UserFromMention

      def initialize(importer, project_id)
        @importer = importer
        @project_id = project_id
      end

      attr_reader :project_id, :importer

      def foo(mention)
        user_from_cache(mention)
      end

      def bar(hash)
        cache_multiple(hash)
      end
    end
  end

  subject(:example_class) { example.new(importer, project_id) }

  describe '#user_from_cache' do
    it 'returns nil if the cache is empty' do
      expect(example_class.foo(username)).to be_nil
    end

    context 'when the username and email is cached' do
      before do
        ::Gitlab::Cache::Import::Caching.write(cache_key, email)
      end

      context 'if a user with the email does not exist' do
        it 'returns nil' do
          expect(example_class.foo(username)).to be_nil
        end
      end

      context 'if a user with the email exists' do
        let!(:user) { create(:user, email: email) }

        it 'returns the user' do
          expect(example_class.foo(username)).to eq(user)
        end
      end
    end
  end

  describe '#cache_multiple' do
    it 'calls write_multiple with the hash' do
      expect(Gitlab::Cache::Import::Caching).to receive(:write_multiple).with(hash, timeout: 72.hours)

      example_class.bar(hash)
    end
  end
end
