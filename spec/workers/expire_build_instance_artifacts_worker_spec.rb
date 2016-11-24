require 'spec_helper'

describe ExpireBuildInstanceArtifactsWorker do
  include RepoHelpers

  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      worker.perform(build.id)
    end

    context 'with expired artifacts' do
      let(:artifacts_expiry) { { artifacts_expire_at: Time.now - 7.days } }

      context 'when associated project is valid' do
        let(:build) do
          create(:ci_build, :artifacts, artifacts_expiry)
        end

        it 'does expire' do
          expect(build.reload.artifacts_expired?).to be_truthy
        end

        it 'does remove files' do
          expect(build.reload.artifacts_file.exists?).to be_falsey
        end

        it 'does nullify artifacts_file column' do
          expect(build.reload.artifacts_file_identifier).to be_nil
        end
      end

      context 'when associated project was removed' do
        let(:build) do
          create(:ci_build, :artifacts, artifacts_expiry) do |build|
            build.project.delete
          end
        end

        it 'does not remove artifacts' do
          expect(build.reload.artifacts_file.exists?).to be_truthy
        end
      end
    end

    context 'with not yet expired artifacts' do
      let(:build) do
        create(:ci_build, :artifacts, artifacts_expire_at: Time.now + 7.days)
      end

      it 'does not expire' do
        expect(build.reload.artifacts_expired?).to be_falsey
      end

      it 'does not remove files' do
        expect(build.reload.artifacts_file.exists?).to be_truthy
      end

      it 'does not nullify artifacts_file column' do
        expect(build.reload.artifacts_file_identifier).not_to be_nil
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

      it 'does not nullify artifacts_file column' do
        expect(build.reload.artifacts_file_identifier).not_to be_nil
      end
    end

    context 'for expired artifacts' do
      let(:build) { create(:ci_build, artifacts_expire_at: Time.now - 7.days) }

      it 'is still expired' do
        expect(build.reload.artifacts_expired?).to be_truthy
      end
    end
  end
end
