# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::BackfillDeploymentClustersFromDeployments, :migration, schema: 20200227140242 do
  subject { described_class.new }

  describe '#perform' do
    it 'backfills deployment_cluster for all deployments in the given range with a non-null cluster_id' do
      deployment_clusters = table(:deployment_clusters)

      namespace = table(:namespaces).create(name: 'the-namespace', path: 'the-path')
      project = table(:projects).create(name: 'the-project', namespace_id: namespace.id)
      environment = table(:environments).create(name: 'the-environment', project_id: project.id, slug: 'slug')
      cluster = table(:clusters).create(name: 'the-cluster')

      deployment_data = { cluster_id: cluster.id, project_id: project.id, environment_id: environment.id, ref: 'abc', tag: false, sha: 'sha', status: 1 }
      expected_deployment_1 = create_deployment(**deployment_data)
      create_deployment(**deployment_data, cluster_id: nil) # no cluster_id
      expected_deployment_2 = create_deployment(**deployment_data)
      out_of_range_deployment = create_deployment(**deployment_data, cluster_id: cluster.id) # expected to be out of range

      # to test "ON CONFLICT DO NOTHING"
      existing_record_for_deployment_2 = deployment_clusters.create(
        deployment_id: expected_deployment_2.id,
        cluster_id: expected_deployment_2.cluster_id,
        kubernetes_namespace: 'production'
      )

      subject.perform(expected_deployment_1.id, out_of_range_deployment.id - 1)

      expect(deployment_clusters.all.pluck(:deployment_id, :cluster_id, :kubernetes_namespace)).to contain_exactly(
        [expected_deployment_1.id, cluster.id, nil],
        [expected_deployment_2.id, cluster.id, existing_record_for_deployment_2.kubernetes_namespace]
      )
    end

    def create_deployment(**data)
      @iid ||= 0
      @iid += 1
      table(:deployments).create(iid: @iid, **data)
    end
  end
end
