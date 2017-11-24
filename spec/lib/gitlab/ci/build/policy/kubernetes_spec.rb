require 'spec_helper'

describe Gitlab::Ci::Build::Policy::Kubernetes do
  let(:pipeline) { create(:ci_pipeline, project: project) }

  context 'when kubernetes service is active' do
    shared_examples 'correct behavior for satisfied_by?' do
      it 'is satisfied by a kubernetes pipeline' do
        expect(described_class.new('active'))
          .to be_satisfied_by(pipeline)
      end
    end

    context 'when user configured kubernetes from Integration > Kubernetes' do
      let(:project) { create(:kubernetes_project) }

      it_behaves_like 'correct behavior for satisfied_by?'
    end

    context 'when user configured kubernetes from CI/CD > Clusters' do
      let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:project) { cluster.project }

      it_behaves_like 'correct behavior for satisfied_by?'
    end
  end

  context 'when kubernetes service is inactive' do
    set(:project) { create(:project) }

    it 'is not satisfied by a pipeline without kubernetes available' do
      expect(described_class.new('active'))
        .not_to be_satisfied_by(pipeline)
    end
  end

  context 'when kubernetes policy is invalid' do
    it 'raises an error' do
      expect { described_class.new('unknown') }
        .to raise_error(described_class::UnknownPolicyError)
    end
  end
end
