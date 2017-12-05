require 'spec_helper'

describe ExpireBuildInstanceArtifactsWorker do
  include RepoHelpers

  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      worker.perform(build.id)
    end

    context 'with expired artifacts' do
      context 'when associated project is valid' do
        let(:build) { create(:ci_build, :artifacts, :expired) }

        it 'does expire' do
          expect(build.reload.artifacts_expired?).to be_truthy
        end

        it 'does remove files' do
          expect(build.reload.artifacts_file.exists?).to be_falsey
        end

        it 'does remove the job artifact record' do
          expect(build.reload.job_artifacts_archive).to be_nil
        end
      end
    end

    context 'with not yet expired artifacts' do
      set(:build) do
        create(:ci_build, :artifacts, artifacts_expire_at: Time.now + 7.days)
      end

      it 'does not expire' do
        expect(build.reload.artifacts_expired?).to be_falsey
      end

      it 'does not remove files' do
        expect(build.reload.artifacts_file.exists?).to be_truthy
      end

      it 'does not remove the job artifact record' do
        expect(build.reload.job_artifacts_archive).not_to be_nil
      end
    end

    context 'without expire date' do
      let(:build) { create(:ci_build, :artifacts) }

      it 'does not expire' do
        expect(build.reload.artifacts_expired?).to be_falsey
      end

      it 'does not remove files' do
        expect(build.reload.artifacts_file.exists?).to be_truthy
      end

      it 'does not remove the job artifact record' do
        expect(build.reload.job_artifacts_archive).not_to be_nil
      end
    end

    context 'for expired artifacts' do
      let(:build) { create(:ci_build, :expired) }

      it 'is still expired' do
        expect(build.reload.artifacts_expired?).to be_truthy
      end
    end
  end
end
