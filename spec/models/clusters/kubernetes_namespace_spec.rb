# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::KubernetesNamespace, type: :model do
  it { should belong_to(:cluster_project) }
  it { should have_one(:project) }
  it { should have_one(:cluster) }

  describe '#set_cluster_namespace_and_service_account' do
    let(:cluster) { platform.cluster }
    let(:cluster_project) { create(:cluster_project, cluster: cluster) }
    let(:kubernetes_namespace) { build(:cluster_kubernetes_namespace, cluster_project: cluster_project) }

    describe '#namespace' do
      let(:platform) { create(:cluster_platform_kubernetes, namespace: namespace) }

      subject { kubernetes_namespace.namespace }

      context 'when kubernetes platform has a namespace assigned' do
        let(:namespace) { 'my-own-namespace' }

        it 'should copy the namespace' do
          kubernetes_namespace.save

          is_expected.to eq('my-own-namespace')
        end
      end

      context 'when kubernetes platform does not have namespace assigned' do
        let(:namespace) { nil }

        it 'should set default namespace' do
          kubernetes_namespace.save
          project_slug = "#{cluster_project.project.path}-#{cluster_project.project_id}"
          is_expected.to eq(project_slug)
        end
      end
    end

    describe '#service_account_namespace' do
      subject { kubernetes_namespace.service_account_name }

      context 'when cluster is not using RBAC' do
        let(:platform) { create(:cluster_platform_kubernetes) }

        it 'should set default service account name' do
          kubernetes_namespace.save

          is_expected.to eq('gitlab')
        end
      end

      context 'when cluster is using RBAC' do
        let(:platform) { create(:cluster_platform_kubernetes, :rbac_enabled) }

        it 'should set a service account name based on namespace' do
          kubernetes_namespace.save

          is_expected.to eq("gitlab-#{kubernetes_namespace.namespace}")
        end
      end
    end
  end

  describe '#ensure_namespace_uniqueness' do
    let(:platform) { create(:cluster_platform_kubernetes) }
    let(:cluster) { platform.cluster }
    let(:cluster_project) { create(:cluster_project, cluster: cluster) }
    let(:kubernetes_namespace) { build(:cluster_kubernetes_namespace, cluster_project: cluster_project) }

    subject { kubernetes_namespace }

    context 'when cluster does not have the kubernetes namespace' do
      it { is_expected.to be_valid }
    end

    context 'when cluster has the same kubernetes namespace' do
      before do
        create(:cluster_kubernetes_namespace,
               namespace: 'my-namespace',
               cluster_project: cluster_project)
      end

      it { is_expected.to_not be_valid }

      it 'should return an error on namespace' do
        subject.save

        project_slug = "#{cluster_project.project.path}-#{cluster_project.project_id}"
        expect(subject.errors[:namespace].first).to eq("Kubernetes namespace #{project_slug} already exists on cluster")
      end
    end
  end
end
