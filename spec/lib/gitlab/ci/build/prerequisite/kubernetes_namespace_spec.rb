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

    context 'build has a deployment' do
      let!(:deployment) { create(:deployment, deployable: build) }

      context 'and a cluster to deploy to' do
        let(:cluster) { create(:cluster, :group) }

        before do
          allow(build.deployment).to receive(:cluster).and_return(cluster)
        end

        it { is_expected.to be_truthy }

        context 'and the cluster is not managed' do
          let(:cluster) { create(:cluster, :not_managed, projects: [build.project]) }

          it { is_expected.to be_falsey }
        end

        context 'and a namespace is already created for this project' do
          let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster, project: build.project) }

          it { is_expected.to be_falsey }
        end

        context 'and cluster is project type' do
          let(:cluster) { create(:cluster, :project) }

          it { is_expected.to be_falsey }
        end
      end

      context 'and no cluster to deploy to' do
        before do
          expect(deployment.cluster).to be_nil
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#complete!' do
    let!(:deployment) { create(:deployment, deployable: build) }
    let(:service) { double(execute: true) }

    subject { described_class.new(build).complete! }

    context 'completion is required' do
      let(:cluster) { create(:cluster, :group) }

      before do
        allow(build.deployment).to receive(:cluster).and_return(cluster)
      end

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
        expect(deployment.cluster).to be_nil
      end

      it 'does not create a namespace' do
        expect(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService).not_to receive(:new)

        subject
      end
    end
  end
end
