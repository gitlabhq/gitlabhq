# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateClusterKubernetesNamespace, :migration, schema: 20181009205043 do
  let(:migration) { described_class.new }
  let(:clusters) { create_list(:cluster, 10, :provided_by_gcp) }
  let(:cluster_projects) { Clusters::Project.all }

  before do
    clusters.each do |cluster|
      create(:cluster_project, cluster: cluster)
    end
  end

  subject { migration.perform(cluster_projects.min, cluster_projects.max) }

  context 'when cluster projects dont have kubernetes namespace related' do
    it 'should create kubernetes namespaces per cluster project' do
      expect do
        subject
      end.to change(Clusters::KubernetesNamespace, :count).by(cluster_projects.count)
    end

    it 'should populate namespace and service account information' do
      subject

      cluster_projects.each do |cluster_project|
        expect(cluster_project.kubernetes_namespace.namespace).not_to be_nil
        expect(cluster_project.kubernetes_namespace.service_account_name).not_to be_nil
      end
    end
  end

  context 'when all cluster projects have kubernetes namespace related' do
    before do
      cluster_projects.each do |cluster_project|
        create(:cluster_kubernetes_namespace, cluster_project: cluster_project)
      end
    end

    it 'should not create any kubernetes namespace' do
      expect do
        subject
      end.not_to change(Clusters::KubernetesNamespace, :count)
    end
  end

  context 'when only some cluster projects have kubernetes namespace related' do
    let(:with_kubernetes_namespace) { cluster_projects.first(6) }
    let(:with_no_kubernetes_namespace) { cluster_projects.last(4) }

    before do
      with_kubernetes_namespace.each do |cluster_project|
        create(:cluster_kubernetes_namespace, cluster_project: cluster_project)
      end
    end

    it 'creates limited number of kubernetes namespace' do
      expect do
        subject
      end.to change(Clusters::KubernetesNamespace, :count).by(with_no_kubernetes_namespace.count)
    end

    it 'should not modify clusters with kubernetes namespace' do
      subject

      with_kubernetes_namespace.each do |cluster_project|
        expect(cluster_project.kubernetes_namespaces.count).to eq(1)
      end
    end

    it 'should create kubernetes namespace for clusters that dont have one' do
      subject

      with_no_kubernetes_namespace.each do |cluster_project|
        expect(cluster_project.kubernetes_namespace).to be_present
      end
    end
  end
end
