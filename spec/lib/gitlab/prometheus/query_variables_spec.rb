# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Prometheus::QueryVariables do
  describe '.call' do
    let(:project) { environment.project }
    let(:environment) { create(:environment) }
    let(:slug) { environment.slug }

    subject { described_class.call(environment) }

    it { is_expected.to include(ci_environment_slug: slug) }

    it do
      is_expected.to include(environment_filter:
                             %Q[container_name!="POD",environment="#{slug}"])
    end

    context 'without deployment platform' do
      it { is_expected.to include(kube_namespace: '') }
    end

    context 'with deployment platform' do
      context 'with project cluster' do
        let(:kube_namespace) { environment.deployment_namespace }

        before do
          create(:cluster, :project, :provided_by_user, projects: [project])
        end

        it { is_expected.to include(kube_namespace: kube_namespace) }
      end

      context 'with group cluster' do
        let(:cluster) { create(:cluster, :group, :provided_by_user, groups: [group]) }
        let(:group) { create(:group) }
        let(:project2) { create(:project) }
        let(:kube_namespace) { k8s_ns.namespace }

        let!(:k8s_ns) { create(:cluster_kubernetes_namespace, cluster: cluster, project: project, environment: environment) }
        let!(:k8s_ns2) { create(:cluster_kubernetes_namespace, cluster: cluster, project: project2, environment: environment) }

        before do
          group.projects << project
          group.projects << project2
        end

        it { is_expected.to include(kube_namespace: kube_namespace) }
      end
    end
  end
end
