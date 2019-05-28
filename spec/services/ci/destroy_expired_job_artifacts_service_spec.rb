# frozen_string_literal: true

require 'spec_helper'

describe Ci::DestroyExpiredJobArtifactsService, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  describe '.execute' do
    subject { service.execute }

    let(:service) { described_class.new }
    let!(:artifact) { create(:ci_job_artifact, expire_at: 1.day.ago) }

    it 'destroys expired job artifacts' do
      expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
    end

    context 'when artifact is not expired' do
      let!(:artifact) { create(:ci_job_artifact, expire_at: 1.day.since) }

      it 'does not destroy expired job artifacts' do
        expect { subject }.not_to change { Ci::JobArtifact.count }
      end
    end

    context 'when artifact is permanent' do
      let!(:artifact) { create(:ci_job_artifact, expire_at: nil) }

      it 'does not destroy expired job artifacts' do
        expect { subject }.not_to change { Ci::JobArtifact.count }
      end
    end

    context 'when failed to destroy artifact' do
      before do
        stub_const('Ci::DestroyExpiredJobArtifactsService::LOOP_LIMIT', 10)

        allow_any_instance_of(Ci::JobArtifact)
          .to receive(:destroy!)
          .and_raise(ActiveRecord::RecordNotDestroyed)
      end

      it 'raises an exception and stop destroying' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end

    context 'when exclusive lease has already been taken by the other instance' do
      before do
        stub_exclusive_lease_taken(described_class::EXCLUSIVE_LOCK_KEY, timeout: described_class::LOCK_TIMEOUT)
      end

      it 'raises an error and does not start destroying' do
        expect { subject }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end
    end

    context 'when timeout happens' do
      before do
        stub_const('Ci::DestroyExpiredJobArtifactsService::LOOP_TIMEOUT', 1.second)
        allow_any_instance_of(described_class).to receive(:destroy_batch) { true }
      end

      it 'returns false and does not continue destroying' do
        is_expected.to be_falsy
      end
    end

    context 'when loop reached loop limit' do
      before do
        stub_const('Ci::DestroyExpiredJobArtifactsService::LOOP_LIMIT', 1)
        stub_const('Ci::DestroyExpiredJobArtifactsService::BATCH_SIZE', 1)
      end

      let!(:artifact) { create_list(:ci_job_artifact, 2, expire_at: 1.day.ago) }

      it 'raises an error and does not continue destroying' do
        is_expected.to be_falsy
      end

      it 'destroys one artifact' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
      end
    end

    context 'when there are no artifacts' do
      let!(:artifact) { }

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when there are artifacts more than batch sizes' do
      before do
        stub_const('Ci::DestroyExpiredJobArtifactsService::BATCH_SIZE', 1)
      end

      let!(:artifact) { create_list(:ci_job_artifact, 2, expire_at: 1.day.ago) }

      it 'destroys all expired artifacts' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(-2)
      end
    end
  end
end
