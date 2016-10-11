require 'spec_helper'

describe ExpireBuildArtifactsWorker do
  include RepoHelpers

  let(:worker) { described_class.new }

  before { Sidekiq::Worker.clear_all }

  describe '#perform' do
    before { build }

    subject! do
      Sidekiq::Testing.fake! { worker.perform }
    end

    context 'with expired artifacts' do
      let(:build) { create(:ci_build, :artifacts, artifacts_expire_at: Time.now - 7.days) }

      it 'enqueues that build' do
        expect(jobs_enqueued.size).to eq(1)
        expect(jobs_enqueued[0]["args"]).to eq([build.id])
      end
    end

    context 'with not yet expired artifacts' do
      let(:build) { create(:ci_build, :artifacts, artifacts_expire_at: Time.now + 7.days) }

      it 'does not enqueue that build' do
        expect(jobs_enqueued.size).to eq(0)
      end
    end

    context 'without expire date' do
      let(:build) { create(:ci_build, :artifacts) }

      it 'does not enqueue that build' do
        expect(jobs_enqueued.size).to eq(0)
      end
    end

    def jobs_enqueued
      Sidekiq::Queues.jobs_by_worker['ExpireBuildInstanceArtifactsWorker']
    end
  end
end
