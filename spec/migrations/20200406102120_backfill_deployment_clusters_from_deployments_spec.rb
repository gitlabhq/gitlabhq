# frozen_string_literal: true

require 'spec_helper'
require_migration!('backfill_deployment_clusters_from_deployments')

RSpec.describe BackfillDeploymentClustersFromDeployments, :migration, :sidekiq, schema: 20200227140242 do
  describe '#up' do
    it 'schedules BackfillDeploymentClustersFromDeployments background jobs' do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      namespace = table(:namespaces).create!(name: 'the-namespace', path: 'the-path')
      project = table(:projects).create!(name: 'the-project', namespace_id: namespace.id)
      environment = table(:environments).create!(name: 'the-environment', project_id: project.id, slug: 'slug')
      cluster = table(:clusters).create!(name: 'the-cluster')

      deployment_data = { cluster_id: cluster.id, project_id: project.id, environment_id: environment.id, ref: 'abc', tag: false, sha: 'sha', status: 1 }

      # batch 1
      batch_1_begin = create_deployment(**deployment_data)
      batch_1_end = create_deployment(**deployment_data)

      # value that should not be included due to default scope
      create_deployment(**deployment_data, cluster_id: nil)

      # batch 2
      batch_2_begin = create_deployment(**deployment_data)
      batch_2_end = create_deployment(**deployment_data)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          # batch 1
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, batch_1_begin.id, batch_1_end.id)

          # batch 2
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, batch_2_begin.id, batch_2_end.id)

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end

    def create_deployment(**data)
      @iid ||= 0
      @iid += 1
      table(:deployments).create!(iid: @iid, **data)
    end
  end
end
