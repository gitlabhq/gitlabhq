# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEnvironmentIdDeploymentMergeRequests, schema: 20200312134637 do
  let(:environments)              { table(:environments) }
  let(:merge_requests)            { table(:merge_requests) }
  let(:deployments)               { table(:deployments) }
  let(:deployment_merge_requests) { table(:deployment_merge_requests) }
  let(:namespaces)                { table(:namespaces) }
  let(:projects)                  { table(:projects) }

  subject(:migration) { described_class.new }

  it 'correctly backfills environment_id column' do
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)

    production = environments.create!(project_id: project.id, name: 'production', slug: 'production')
    staging = environments.create!(project_id: project.id, name: 'staging', slug: 'staging')

    mr = merge_requests.create!(source_branch: 'x', target_branch: 'master', target_project_id: project.id)

    deployment1 = deployments.create!(environment_id: staging.id, iid: 1, project_id: project.id, ref: 'master', tag: false, sha: '123abcdef', status: 1)
    deployment2 = deployments.create!(environment_id: production.id, iid: 2, project_id: project.id, ref: 'master', tag: false, sha: '123abcdef', status: 1)
    deployment3 = deployments.create!(environment_id: production.id, iid: 3, project_id: project.id, ref: 'master', tag: false, sha: '123abcdef', status: 1)

    # mr is tracked twice in production through deployment2 and deployment3
    deployment_merge_requests.create!(deployment_id: deployment1.id, merge_request_id: mr.id)
    deployment_merge_requests.create!(deployment_id: deployment2.id, merge_request_id: mr.id)
    deployment_merge_requests.create!(deployment_id: deployment3.id, merge_request_id: mr.id)

    expect(deployment_merge_requests.where(environment_id: nil).count).to eq(3)

    migration.backfill_range(1, mr.id)

    expect(deployment_merge_requests.where(environment_id: nil).count).to be_zero
    expect(deployment_merge_requests.count).to eq(2)

    production_deployments = deployment_merge_requests.where(environment_id: production.id)
    expect(production_deployments.count).to eq(1)
    expect(production_deployments.first.deployment_id).to eq(deployment2.id)

    expect(deployment_merge_requests.where(environment_id: staging.id).count).to eq(1)
  end
end
