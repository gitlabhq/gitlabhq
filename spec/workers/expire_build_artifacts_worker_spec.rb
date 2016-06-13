require 'spec_helper'

describe ExpireBuildArtifactsWorker do
  include RepoHelpers

  let(:worker) { described_class.new }

  describe '#perform' do
    before { build }

    subject! { worker.perform }

    context 'with expired artifacts' do
      let!(:build) { create(:ci_build, :artifacts, artifacts_expire_at: Time.now - 7.days) }

      it 'does expire' do
        expect(build.reload.artifacts_expired?).to be_truthy
      end
    end

    context 'with not yet expired artifacts' do
      let!(:build) { create(:ci_build, :artifacts, artifacts_expire_at: Time.now + 7.days) }

      it 'does not expire' do
        expect(build.reload.artifacts_expired?).to be_truthy
      end
    end

    context 'without expire date' do
      let!(:build) { create(:ci_build, :artifacts) }

      it 'does not expire' do
        expect(build.reload.artifacts_expired?).to be_falsey
      end
    end

    context 'for expired artifacts' do
      let!(:build) { create(:ci_build, artifacts_expire_at: Time.now - 7.days) }

      it 'does not erase artifacts' do
        expect_any_instance_of(Ci::Build).not_to have_received(:erase_artifacts!)
      end

      it 'does expire' do
        expect(build.reload.artifacts_expired?).to be_truthy
      end
    end
  end
end
