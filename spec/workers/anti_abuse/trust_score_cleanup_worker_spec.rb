# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::TrustScoreCleanupWorker, :clean_gitlab_redis_shared_state, feature_category: :instance_resiliency do
  let(:worker) { described_class.new }
  let(:source) { Enums::Abuse::Source.sources[:telesign] }
  let_it_be(:user) { create(:user) }

  subject(:perform) { worker.perform(user.id, source) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [user.id, source] }
  end

  context "when the user does not exist" do
    before do
      allow(User).to receive(:find_by_id).with(user.id).and_return(nil)
    end

    it 'returns early' do
      expect(Rails.cache).not_to receive(:exist?)
      expect(AntiAbuse::UserTrustScore).not_to receive(:new)

      perform
    end
  end

  context "when the user exists" do
    context "when the cache key exists" do
      it 'returns early' do
        expect(Rails.cache).to receive(:exist?).and_return(true)
        expect(AntiAbuse::UserTrustScore).not_to receive(:new)

        perform
      end
    end

    context "when the cache key does not exist" do
      it 'removes old scores for the user' do
        expect(Rails.cache).to receive(:exist?).and_return(false)
        expect_next_instance_of(AntiAbuse::UserTrustScore, user) do |instance|
          expect(instance).to receive(:remove_old_scores).with(source)
        end

        perform
      end

      it 'sets the cache_key' do
        cache_key = "abuse:trust_score_cleanup_worker:#{user.id}:#{source}"
        expect(Rails.cache).to receive(:write).with(cache_key, true, expires_in: 5.minutes)

        perform
      end
    end
  end
end
