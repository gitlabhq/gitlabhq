# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200312134637_backfill_environment_id_on_deployment_merge_requests.rb')

describe BackfillEnvironmentIdOnDeploymentMergeRequests do
  let(:environments)              { table(:environments) }
  let(:merge_requests)            { table(:merge_requests) }
  let(:deployments)               { table(:deployments) }
  let(:deployment_merge_requests) { table(:deployment_merge_requests) }
  let(:namespaces)                { table(:namespaces) }
  let(:projects)                  { table(:projects) }

  let(:migration_worker) { double('BackgroundMigrationWorker') }

  before do
    stub_const('BackgroundMigrationWorker', migration_worker)
  end

  it 'schedules nothing when there are no entries' do
    expect(migration_worker).not_to receive(:perform_in)

    migrate!
  end

  it 'batches the workload' do
    stub_const("#{described_class.name}::BATCH_SIZE", 10)

    namespace = namespaces.create!(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)

    environment = environments.create!(project_id: project.id, name: 'staging', slug: 'staging')

    # Batching is based on DeploymentMergeRequest.merge_request_id, in order to test it
    # we must generate more than described_class::BATCH_SIZE merge requests, deployments,
    # and deployment_merge_requests entries
    entries = 13
    expect(entries).to be > described_class::BATCH_SIZE

    # merge requests and deployments bulk generation
    mrs_params = []
    deployments_params = []
    entries.times do |i|
      mrs_params << { source_branch: 'x', target_branch: 'master', target_project_id: project.id }

      deployments_params << { environment_id: environment.id, iid: i + 1, project_id: project.id, ref: 'master', tag: false, sha: '123abcdef', status: 1 }
    end

    all_mrs = merge_requests.insert_all(mrs_params)
    all_deployments = deployments.insert_all(deployments_params)

    # deployment_merge_requests bulk generation
    dmr_params = []
    entries.times do |index|
      mr_id = all_mrs.rows[index].first
      deployment_id = all_deployments.rows[index].first

      dmr_params << { deployment_id: deployment_id, merge_request_id: mr_id }
    end

    deployment_merge_requests.insert_all(dmr_params)

    first_batch_limit = dmr_params[described_class::BATCH_SIZE][:merge_request_id]
    second_batch_limit = dmr_params.last[:merge_request_id]

    expect(migration_worker).to receive(:perform_in)
                                  .with(
                                    0,
                                    'BackfillEnvironmentIdDeploymentMergeRequests',
                                    [1, first_batch_limit]
                                  )
    expect(migration_worker).to receive(:perform_in)
                                  .with(
                                    described_class::DELAY,
                                    'BackfillEnvironmentIdDeploymentMergeRequests',
                                    [first_batch_limit + 1, second_batch_limit]
                                  )

    migrate!
  end
end
