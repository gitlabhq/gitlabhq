require 'spec_helper'

describe Clusters::Project do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:kubernetes_namespaces) }

  describe '#kubernetes_namespace' do
    let(:cluster) { create(:cluster, :provided_by_gcp) }
    let(:cluster_project) { create(:cluster_project, cluster: cluster) }

    subject { cluster_project.kubernetes_namespace }

    before do
      kubernetes_namespace
    end

    context 'when is just one' do
      let(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster_project: cluster_project) }

      it 'returns that one' do
        is_expected.to eq(kubernetes_namespace)
      end
    end

    context 'when cluster has many kubernetes namespaces' do
      let(:namespaces) { %w(namespace1 namespace2 namespace3) }

      let(:kubernetes_namespaces) do
        namespaces.each do |namespace|
          cluster.platform_kubernetes.update_column(:namespace, namespace)
          create(:cluster_kubernetes_namespace, cluster_project: cluster_project)
        end

        cluster_project.kubernetes_namespaces
      end

      let(:kubernetes_namespace) { kubernetes_namespaces.last }

      it 'returns the last one' do
        is_expected.to eq(kubernetes_namespace)
      end
    end
  end
end
