# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDeploymentMergeRequestsProjectId, feature_category: :continuous_delivery do
  let(:connection) { ApplicationRecord.connection }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:start_cursor) { [0, 0] }
  let(:end_cursor) { [deployments.maximum(:id), 0] }

  let(:migration) do
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :deployment_merge_requests,
      batch_column: :deployment_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    )
  end

  shared_context 'for database tables' do
    let(:namespaces) { table(:namespaces) }
    let(:organizations) { table(:organizations) }
    let(:environments) { table(:environments) }
    let(:deployments) { table(:deployments) { |t| t.primary_key = :id } }
    let(:deployment_merge_requests) { table(:deployment_merge_requests) { |t| t.primary_key = :deployment_id } }
    let(:merge_requests) { table(:merge_requests) { |t| t.primary_key = :id } }
    let(:projects) { table(:projects) }
  end

  shared_context 'for namespaces' do
    let(:namespace1) { namespaces.create!(name: 'namespace 1', path: 'namespace1', organization_id: organization.id) }
    let(:namespace2) { namespaces.create!(name: 'namespace 2', path: 'namespace2', organization_id: organization.id) }
    let(:namespace3) { namespaces.create!(name: 'namespace 3', path: 'namespace3', organization_id: organization.id) }
    let(:namespace4) { namespaces.create!(name: 'namespace 4', path: 'namespace4', organization_id: organization.id) }
  end

  shared_context 'for projects' do
    let(:project1) do
      projects.create!(
        namespace_id: namespace1.id,
        project_namespace_id: namespace1.id,
        organization_id: organization.id
      )
    end

    let(:project2) do
      projects.create!(
        namespace_id: namespace2.id,
        project_namespace_id: namespace2.id,
        organization_id: organization.id
      )
    end

    let(:project3) do
      projects.create!(
        namespace_id: namespace3.id,
        project_namespace_id: namespace3.id,
        organization_id: organization.id
      )
    end

    let(:project4) do
      projects.create!(
        namespace_id: namespace4.id,
        project_namespace_id: namespace4.id,
        organization_id: organization.id
      )
    end

    let(:commit) { "6d4b0f7cff5f37573aba97cebfd5692ea1689925" }
    let(:production_environment) { environments.create!(project_id: project1.id, tier: 0, name: 'prod', slug: 'prod') }
  end

  shared_context 'for merge requests' do
    let!(:merge_request_1) do
      merge_requests.create!(
        target_project_id: project1.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project1.id
      )
    end

    let!(:merge_request_2) do
      merge_requests.create!(
        target_project_id: project2.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project2.id
      )
    end

    let!(:merge_request_3) do
      merge_requests.create!(
        target_project_id: project3.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project3.id
      )
    end

    let!(:merge_request_4) do
      merge_requests.create!(
        target_project_id: project4.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project4.id
      )
    end
  end

  shared_context 'for deployment and merge requests' do
    let!(:deployment1) do
      deployments.create!(
        iid: 1,
        environment_id: production_environment.id,
        project_id: project1.id,
        status: 1,
        ref: merge_request_1.source_branch,
        sha: commit,
        tag: false
      )
    end

    let!(:deployment2) do
      deployments.create!(
        iid: 2,
        environment_id: production_environment.id,
        project_id: project2.id,
        status: 1,
        ref: merge_request_2.source_branch,
        sha: commit,
        tag: false
      )
    end

    let!(:deployment3) do
      deployments.create!(
        iid: 3,
        environment_id: production_environment.id,
        project_id: project3.id,
        status: 1,
        ref: merge_request_3.source_branch,
        sha: commit,
        tag: false
      )
    end

    let!(:deployment4) do
      deployments.create!(
        iid: 4,
        environment_id: production_environment.id,
        project_id: project4.id,
        status: 1,
        ref: merge_request_4.source_branch,
        sha: commit,
        tag: false
      )
    end

    let!(:deployment_merge_request_1) do
      deployment_merge_requests.create!(deployment_id: deployment1.id,
        merge_request_id: merge_request_1.id, project_id: nil)
    end

    let!(:deployment_merge_request_2) do
      deployment_merge_requests.create!(deployment_id: deployment2.id,
        merge_request_id: merge_request_2.id, project_id: nil)
    end

    let!(:deployment_merge_request_3) do
      deployment_merge_requests.create!(deployment_id: deployment3.id,
        merge_request_id: merge_request_3.id, project_id: nil)
    end

    let!(:deployment_merge_request_4) do
      deployment_merge_requests.create!(deployment_id: deployment4.id,
        merge_request_id: merge_request_4.id, project_id: project4.id)
    end
  end

  include_context 'for database tables'
  include_context 'for namespaces'
  include_context 'for projects'
  include_context 'for merge requests'
  include_context 'for deployment and merge requests'

  describe '#perform' do
    it 'backfills deployment_merge_requests.project_id correctly for relevant records' do
      migration.perform

      expect(deployment_merge_request_1.reload.project_id).to eq(deployment1.project_id)
      expect(deployment_merge_request_2.reload.project_id).to eq(deployment2.project_id)
      expect(deployment_merge_request_3.reload.project_id).to eq(deployment3.project_id)
    end

    it 'does not update deployment_merge_requests with pre-existing project_id' do
      expect { migration.perform }
        .not_to change { deployment_merge_request_4.reload.project_id }
    end
  end
end
