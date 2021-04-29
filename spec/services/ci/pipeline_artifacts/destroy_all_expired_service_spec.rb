# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifacts::DestroyAllExpiredService do
  let(:service) { described_class.new }

  describe '.execute' do
    subject { service.execute }

    context 'when timeout happens' do
      before do
        stub_const('Ci::PipelineArtifacts::DestroyAllExpiredService::LOOP_TIMEOUT', 0.1.seconds)
        allow(service).to receive(:destroy_artifacts_batch) { true }
      end

      it 'returns 0 and does not continue destroying' do
        is_expected.to eq(0)
      end
    end

    context 'when there are no artifacts' do
      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the loop limit is reached' do
      before do
        stub_const('::Ci::PipelineArtifacts::DestroyAllExpiredService::LOOP_LIMIT', 1)
        stub_const('::Ci::PipelineArtifacts::DestroyAllExpiredService::BATCH_SIZE', 1)

        create_list(:ci_pipeline_artifact, 2, :unlocked, expire_at: 1.week.ago)
      end

      it 'destroys one artifact' do
        expect { subject }.to change { Ci::PipelineArtifact.count }.by(-1)
      end

      it 'reports the number of destroyed artifacts' do
        is_expected.to eq(1)
      end
    end

    context 'when there are artifacts more than batch sizes' do
      before do
        stub_const('Ci::PipelineArtifacts::DestroyAllExpiredService::BATCH_SIZE', 1)

        create_list(:ci_pipeline_artifact, 2, :unlocked, expire_at: 1.week.ago)
      end

      it 'destroys all expired artifacts' do
        expect { subject }.to change { Ci::PipelineArtifact.count }.by(-2)
      end

      it 'reports the number of destroyed artifacts' do
        is_expected.to eq(2)
      end
    end

    context 'when artifacts are not expired' do
      before do
        create(:ci_pipeline_artifact, :unlocked, expire_at: 2.days.from_now)
      end

      it 'does not destroy pipeline artifacts' do
        expect { subject }.not_to change { Ci::PipelineArtifact.count }
      end

      it 'reports the number of destroyed artifacts' do
        is_expected.to eq(0)
      end
    end

    context 'when pipeline is locked' do
      before do
        create(:ci_pipeline_artifact, expire_at: 2.weeks.ago)
      end

      it 'does not destroy pipeline artifacts' do
        expect { subject }.not_to change { Ci::PipelineArtifact.count }
      end

      it 'reports the number of destroyed artifacts' do
        is_expected.to eq(0)
      end
    end
  end

  describe '.destroy_artifacts_batch' do
    it 'returns a falsy value without artifacts' do
      expect(service.send(:destroy_artifacts_batch)).to be_falsy
    end
  end
end
