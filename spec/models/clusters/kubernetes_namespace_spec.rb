# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::KubernetesNamespace, type: :model do
  it { is_expected.to belong_to(:cluster_project) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to have_one(:platform_kubernetes) }

  describe 'namespace uniqueness validation' do
    let(:cluster_project) { create(:cluster_project) }

    let(:kubernetes_namespace) do
      build(:cluster_kubernetes_namespace,
            cluster: cluster_project.cluster,
            project: cluster_project.project,
            cluster_project: cluster_project)
    end

    subject  { kubernetes_namespace }

    context 'when cluster is using the namespace' do
      before do
        create(:cluster_kubernetes_namespace,
               cluster: cluster_project.cluster,
               project: cluster_project.project,
               cluster_project: cluster_project,
               namespace: kubernetes_namespace.namespace)
      end

      it { is_expected.not_to be_valid }
    end

    context 'when cluster is not using the namespace' do
      it { is_expected.to be_valid }
    end
  end

  describe '#set_namespace_and_service_account_to_default' do
    let(:cluster) { platform.cluster }
    let(:cluster_project) { create(:cluster_project, cluster: cluster) }
    let(:kubernetes_namespace) do
      create(:cluster_kubernetes_namespace,
            cluster: cluster_project.cluster,
            project: cluster_project.project,
            cluster_project: cluster_project)
    end

    describe 'namespace' do
      let(:platform) { create(:cluster_platform_kubernetes, namespace: namespace) }

      subject { kubernetes_namespace.namespace }

      context 'when platform has a namespace assigned' do
        let(:namespace) { 'platform-namespace' }

        it 'should copy the namespace' do
          is_expected.to eq('platform-namespace')
        end
      end

      context 'when platform does not have namespace assigned' do
        let(:namespace) { nil }

        it 'should set default namespace' do
          project_slug = "#{cluster_project.project.path}-#{cluster_project.project_id}"

          is_expected.to eq(project_slug)
        end
      end
    end

    describe 'service_account_name' do
      let(:platform) { create(:cluster_platform_kubernetes) }

      subject { kubernetes_namespace.service_account_name }

      it 'should set a service account name based on namespace' do
        is_expected.to eq("#{kubernetes_namespace.namespace}-service-account")
      end
    end
  end
end
