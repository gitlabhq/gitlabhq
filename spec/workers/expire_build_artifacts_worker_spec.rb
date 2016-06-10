require 'spec_helper'

describe ExpireBuildArtifactsWorker do
  include RepoHelpers

  let(:worker) { described_class.new }

  describe '#perform' do
    context 'with expired artifacts' do
      let!(:build) { create(:ci_build, :artifacts, artifacts_expire_at: Time.now - 7.days) }

      it do
        expect_any_instance_of(Ci::Build).to receive(:erase_artifacts!)

        worker.perform

        expect(build.reload.artifacts_expired?).to be_truthy
      end
    end

    context 'with not yet expired artifacts' do
      let!(:build) { create(:ci_build, :artifacts, artifacts_expire_at: Time.now + 7.days) }

      it do
        expect_any_instance_of(Ci::Build).not_to receive(:erase_artifacts!)

        worker.perform

        expect(build.reload.artifacts_expired?).to be_falsey
      end
    end

    context 'without expire date' do
      let!(:build) { create(:ci_build, :artifacts) }

      it do
        expect_any_instance_of(Ci::Build).not_to receive(:erase_artifacts!)

        worker.perform
      end
    end

    context 'for expired artifacts' do
      let!(:build) { create(:ci_build, :artifacts, artifacts_expire_at: Time.now - 7.days) }

      before do
        build.erase_artifacts!
        build.save
      end

      it do
        expect_any_instance_of(Ci::Build).not_to receive(:erase_artifacts!)

        worker.perform

        expect(build.reload.artifacts_expired?).to be_truthy
      end
    end
  end
end
