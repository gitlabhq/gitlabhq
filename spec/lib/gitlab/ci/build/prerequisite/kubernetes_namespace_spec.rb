# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Build::Prerequisite::KubernetesNamespace do
  let(:build) { create(:ci_build) }

  describe '#unmet?' do
    subject { described_class.new(build).unmet? }

    context 'build has no deployment' do
      before do
        expect(build.deployment).to be_nil
      end

      it { is_expected.to be_falsey }
    end

    context 'build has a deployment, and no existing kubernetes namespace' do
      let!(:deployment) { create(:deployment, deployable: build) }
      let!(:cluster) { create(:cluster, projects: [build.project]) }

      before do
        expect(build.project.kubernetes_namespaces).to be_empty
      end

      it { is_expected.to be_truthy }
    end

    context 'build has a deployment and kubernetes namespaces' do
      let!(:deployment) { create(:deployment, deployable: build) }
      let!(:cluster) { create(:cluster, projects: [build.project]) }
      let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#complete!' do
    let(:cluster) { create(:cluster, projects: [build.project]) }
    let(:service) { double(execute: true) }

    subject { described_class.new(build).complete! }

    context 'completion is required' do
      let!(:deployment) { create(:deployment, deployable: build) }

      it 'creates a kubernetes namespace' do
        expect(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService)
          .to receive(:new)
          .with(cluster: cluster, kubernetes_namespace: instance_of(Clusters::KubernetesNamespace))
          .and_return(service)

        expect(service).to receive(:execute).once

        subject
      end
    end

    context 'completion is not required' do
      before do
        expect(build.deployment).to be_nil
      end

      it 'does not create a namespace' do
        expect(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService).not_to receive(:new)

        subject
      end
    end
  end
end
