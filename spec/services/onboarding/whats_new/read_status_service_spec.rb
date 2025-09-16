# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::WhatsNew::ReadStatusService, :clean_gitlab_redis_shared_state, feature_category: :onboarding do
  let(:user_id) { 123 }
  let(:version_digest) { 'abc123' }
  let(:service) { described_class.new(user_id, version_digest) }
  let(:redis_set_key) { "whats_new:#{version_digest}:user:#{user_id}:read_articles" }

  describe '#mark_article_as_read' do
    let(:article_id) { '5' }

    before do
      allow(ReleaseHighlight).to receive(:most_recent_item_count).and_return(10)
    end

    context 'when article_id is valid' do
      it 'marks the article as read and returns success' do
        result = service.mark_article_as_read(article_id)

        expect(result).to be_success
      end
    end

    context 'when article_id is invalid' do
      it 'returns error' do
        result = service.mark_article_as_read(11)

        expect(result).to be_error
        expect(result.message).to eq('invalid article id')
      end
    end

    context 'when article is already marked as read' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.sadd(redis_set_key, article_id)
        end
      end

      it 'returns error message' do
        result = service.mark_article_as_read(article_id)

        expect(result).to be_error
        expect(result.message).to eq('article already marked as read')
      end

      it 'does not call redis sadd again' do
        redis_double = instance_double(Redis)
        allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis_double)
        allow(redis_double).to receive(:sismember).and_return(true)

        expect(redis_double).not_to receive(:sadd)

        service.mark_article_as_read(article_id)
      end
    end
  end

  describe '#most_recent_version_read_articles' do
    context 'when there are read articles' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.sadd(redis_set_key, 1, 3, 7)
          redis.sadd("whats_new:different_version:user:#{user_id}:read_articles", 2)
          redis.sadd("whats_new:#{version_digest}:user:999:read_articles", 5)
        end
      end

      it 'returns array of article IDs that have been read' do
        result = service.most_recent_version_read_articles

        expect(result).to contain_exactly(1, 3, 7)
      end

      it 'only returns articles for the specific version and user' do
        result = service.most_recent_version_read_articles

        expect(result).not_to include(2)
        expect(result).not_to include(5)
        expect(result).to contain_exactly(1, 3, 7)
      end
    end

    context 'when there are no read articles' do
      it 'returns empty array' do
        result = service.most_recent_version_read_articles

        expect(result).to eq([])
      end
    end
  end
end
