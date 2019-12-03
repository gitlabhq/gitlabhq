# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Build::Prerequisite::KubernetesNamespace do
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
      let!(:deployment) { create(:deployment, deployable: build, cluster: cluster) }

      context 'and a cluster to deploy to' do
        let(:cluster) { create(:cluster, :group) }

        it { is_expected.to be_truthy }

        context 'and the cluster is not managed' do
          let(:cluster) { create(:cluster, :not_managed, projects: [build.project]) }

          it { is_expected.to be_falsey }
        end

        context 'and a namespace is already created for this project' do
          let(:kubernetes_namespace) { instance_double(Clusters::KubernetesNamespace, service_account_token: 'token') }

          before do
            allow(Clusters::KubernetesNamespaceFinder).to receive(:new)
              .and_return(double(execute: kubernetes_namespace))
          end

          context 'and the knative version role binding is missing' do
            before do
              allow(Clusters::KnativeVersionRoleBindingFinder).to receive(:new)
                .and_return(double(execute: nil))
            end

            it { is_expected.to be_truthy }
          end

          context 'and the knative version role binding already exists' do
            before do
              allow(Clusters::KnativeVersionRoleBindingFinder).to receive(:new)
                .and_return(double(execute: true))
            end

            it { is_expected.to be_falsey }

            context 'and the service_account_token is blank' do
              let(:kubernetes_namespace) { instance_double(Clusters::KubernetesNamespace, service_account_token: nil) }

              it { is_expected.to be_truthy }
            end
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
      let(:cluster) { create(:cluster, :group) }
      let(:deployment) { create(:deployment, cluster: cluster) }
      let(:service) { double(execute: true) }
      let(:kubernetes_namespace) { double }

      before do
        allow(prerequisite).to receive(:unmet?).and_return(true)
        allow(build).to receive(:deployment).and_return(deployment)
      end

      context 'kubernetes namespace does not exist' do
        let(:namespace_builder) { double(execute: kubernetes_namespace)}

        before do
          allow(Clusters::KubernetesNamespaceFinder).to receive(:new)
            .and_return(double(execute: nil))
        end

        it 'creates a namespace using a new record' do
          expect(Clusters::BuildKubernetesNamespaceService)
            .to receive(:new)
            .with(cluster, environment: deployment.environment)
            .and_return(namespace_builder)

          expect(Clusters::Kubernetes::CreateOrUpdateNamespaceService)
            .to receive(:new)
            .with(cluster: cluster, kubernetes_namespace: kubernetes_namespace)
            .and_return(service)

          expect(service).to receive(:execute).once

          subject
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
            .with(cluster: cluster, kubernetes_namespace: kubernetes_namespace)
            .and_return(service)

          subject
        end
      end

      context 'knative version role binding is missing' do
        before do
          allow(Clusters::KubernetesNamespaceFinder).to receive(:new)
            .and_return(double(execute: kubernetes_namespace))
          allow(Clusters::KnativeVersionRoleBindingFinder).to receive(:new)
            .and_return(double(execute: nil))
        end

        it 'creates the knative version role binding' do
          expect(Clusters::Kubernetes::CreateOrUpdateNamespaceService)
            .to receive(:new)
            .with(cluster: cluster, kubernetes_namespace: kubernetes_namespace)
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
