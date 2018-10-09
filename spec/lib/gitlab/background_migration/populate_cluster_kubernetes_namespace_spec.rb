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

  it 'should populate namespace and service account information' do
    subject

    cluster_projects.each do |cluster_project|
      expect(cluster_project.kubernetes_namespace.namespace).not_to be_nil
      expect(cluster_project.kubernetes_namespace.service_account_name).not_to be_nil
    end
  end
end
