# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Prerequisite::KubernetesNamespace, feature_category: :continuous_delivery do
  describe '#unmet?' do
    let(:build) { create(:ci_build) }

    subject { described_class.new(build).unmet? }

    context 'build has no deployment' do
      before do
        expect(build.deployment).to be_nil
      end

      it { is_expected.to be_falsey }
    end

    context 'build has a deployment' do
      context 'and a cluster to deploy to' do
        let!(:deployment) { create(:deployment, :on_cluster, deployable: build) }

        it { is_expected.to be_truthy }

        context 'and the cluster is not managed' do
          let!(:deployment) { create(:deployment, :on_cluster_not_managed, deployable: build) }

          it { is_expected.to be_falsey }
        end

        context 'and a namespace is already created for this project' do
          let(:kubernetes_namespace) { instance_double(Clusters::KubernetesNamespace, service_account_token: 'token') }

          before do
            allow(Clusters::KubernetesNamespaceFinder).to receive(:new)
              .and_return(double(execute: kubernetes_namespace))
          end

          it { is_expected.to be_falsey }

          context 'and the service_account_token is blank' do
            let(:kubernetes_namespace) { instance_double(Clusters::KubernetesNamespace, service_account_token: nil) }

            it { is_expected.to be_truthy }
          end
        end
      end

      context 'and no cluster to deploy to' do
        let(:cluster) { nil }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#complete!' do
    let(:build) { create(:ci_build) }
    let(:prerequisite) { described_class.new(build) }

    subject { prerequisite.complete! }

    context 'completion is required' do
      let(:cluster) { deployment.cluster }
      let(:deployment) { create(:deployment, :on_cluster) }
      let(:service) { double(execute: true) }
      let(:kubernetes_namespace) { double }

      before do
        allow(prerequisite).to receive(:unmet?).and_return(true)
        allow(build).to receive(:deployment).and_return(deployment)
      end

      context 'kubernetes namespace does not exist' do
        let(:namespace_builder) { double(execute: kubernetes_namespace) }

        before do
          allow(Clusters::KubernetesNamespaceFinder).to receive(:new)
            .and_return(double(execute: nil))
        end

        it 'creates a namespace using a new record' do
          expect(Clusters::BuildKubernetesNamespaceService)
            .to receive(:new)
            .with(deployment.cluster, environment: deployment.environment)
            .and_return(namespace_builder)

          expect(Clusters::Kubernetes::CreateOrUpdateNamespaceService)
            .to receive(:new)
            .with(cluster: deployment.cluster, kubernetes_namespace: kubernetes_namespace)
            .and_return(service)

          expect(service).to receive(:execute).once

          subject
        end

        context 'the build has a namespace configured via CI template' do
          let(:kubernetes_namespace) { double(namespace: existing_namespace) }

          before do
            allow(build).to receive(:expanded_kubernetes_namespace)
              .and_return(requested_namespace)
          end

          context 'the requested namespace matches the default' do
            let(:requested_namespace) { 'production' }
            let(:existing_namespace) { requested_namespace }

            it 'creates a namespace' do
              expect(Clusters::BuildKubernetesNamespaceService)
                .to receive(:new)
                .with(deployment.cluster, environment: deployment.environment)
                .and_return(namespace_builder)

              expect(Clusters::Kubernetes::CreateOrUpdateNamespaceService)
                .to receive(:new)
                .with(cluster: deployment.cluster, kubernetes_namespace: kubernetes_namespace)
                .and_return(service)

              expect(service).to receive(:execute).once

              subject
            end
          end

          context 'the requested namespace differs from the default' do
            let(:requested_namespace) { 'production' }
            let(:existing_namespace) { 'other-namespace' }

            it 'does not create a namespace' do
              expect(Clusters::Kubernetes::CreateOrUpdateNamespaceService).not_to receive(:new)

              subject
            end
          end
        end
      end

      context 'kubernetes namespace exists (but has no service_account_token)' do
        before do
          allow(Clusters::KubernetesNamespaceFinder).to receive(:new)
            .and_return(double(execute: kubernetes_namespace))
        end

        it 'creates a namespace using the tokenless record' do
          expect(Clusters::BuildKubernetesNamespaceService).not_to receive(:new)

          expect(Clusters::Kubernetes::CreateOrUpdateNamespaceService)
            .to receive(:new)
            .with(cluster: deployment.cluster, kubernetes_namespace: kubernetes_namespace)
            .and_return(service)

          subject
        end
      end
    end

    context 'completion is not required' do
      before do
        allow(prerequisite).to receive(:unmet?).and_return(false)
      end

      it 'does not create a namespace' do
        expect(Clusters::Kubernetes::CreateOrUpdateNamespaceService).not_to receive(:new)

        subject
      end
    end
  end
end
