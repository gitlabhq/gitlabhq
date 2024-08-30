# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::TrustScoreWorker, :clean_gitlab_redis_shared_state, feature_category: :instance_resiliency do
  let(:worker) { described_class.new }
  let_it_be(:user) { create(:user) }

  subject(:perform) { worker.perform(user.id, :telesign, 0.85, 'foo') }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [user.id, :telesign, 0.5] }
  end

  context "when the user does not exist" do
    let(:log_payload) { { 'message' => 'User not found.', 'user_id' => user.id } }

    before do
      allow(User).to receive(:find_by_id).with(user.id).and_return(nil)
    end

    it 'logs an error' do
      expect(Sidekiq.logger).to receive(:info).with(hash_including(log_payload))

      expect { perform }.not_to raise_exception
    end

    it 'does not attempt to create the trust score' do
      expect(AntiAbuse::TrustScore).not_to receive(:create!)

      perform
    end
  end

  context "when the user exists" do
    it 'creates an abuse trust score with the correct data' do
      expect { perform }.to change { AntiAbuse::TrustScore.count }.from(0).to(1)
      expect(AntiAbuse::TrustScore.last.attributes).to include({
        user_id: user.id,
        source: "telesign",
        score: 0.85,
        correlation_id_value: 'foo'
      }.stringify_keys)
    end
  end
end
