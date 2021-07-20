# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Prometheus::QueryVariables do
  describe '.call' do
    let_it_be_with_refind(:environment) { create(:environment) }

    let(:project) { environment.project }
    let(:slug) { environment.slug }
    let(:params) { {} }

    subject { described_class.call(environment, **params) }

    it { is_expected.to include(ci_environment_slug: slug) }
    it { is_expected.to include(ci_project_name: project.name) }
    it { is_expected.to include(ci_project_namespace: project.namespace.name) }
    it { is_expected.to include(ci_project_path: project.full_path) }
    it { is_expected.to include(ci_environment_name: environment.name) }

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

    context '__range' do
      context 'when start_time and end_time are present' do
        let(:params) do
          {
            start_time: Time.rfc3339('2020-05-29T07:23:05.008Z'),
            end_time: Time.rfc3339('2020-05-29T15:23:05.008Z')
          }
        end

        it { is_expected.to include(__range: "#{8.hours.to_i}s") }
      end

      context 'when start_time and end_time are not present' do
        it { is_expected.to include(__range: nil) }
      end

      context 'when end_time is not present' do
        let(:params) do
          {
            start_time: Time.rfc3339('2020-05-29T07:23:05.008Z')
          }
        end

        it { is_expected.to include(__range: nil) }
      end

      context 'when start_time is not present' do
        let(:params) do
          {
            end_time: Time.rfc3339('2020-05-29T07:23:05.008Z')
          }
        end

        it { is_expected.to include(__range: nil) }
      end
    end
  end
end
