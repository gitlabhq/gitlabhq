# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDeploymentMergeRequestsForBigintConversion, feature_category: :deployment_management do
  let(:connection) { ApplicationRecord.connection }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:start_cursor) { [0, 0] }
  let(:end_cursor) { [deployments.maximum(:id), merge_requests.maximum(:id)] }

  let(:migration) do
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :deployment_merge_requests,
      batch_column: :deployment_id,
      job_arguments: [
        %w[deployment_id merge_request_id environment_id],
        %w[deployment_id_convert_to_bigint merge_request_id_convert_to_bigint environment_id_convert_to_bigint]
      ],
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    )
  end

  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:environments) { table(:environments) }
  let(:deployments) { table(:deployments) }
  let(:deployment_merge_requests) { table(:deployment_merge_requests) }
  let(:merge_requests) { table(:merge_requests) }
  let(:projects) { table(:projects) }

  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:environment1) { environments.create!(project_id: project.id, tier: 0, name: 'prod', slug: 'prod') }
  let(:environment2) { environments.create!(project_id: project.id, tier: 1, name: 'staging', slug: 'staging') }

  let!(:merge_request1) do
    merge_requests.create!(
      target_project_id: project.id,
      target_branch: 'master',
      source_branch: 'feature',
      source_project_id: project.id
    )
  end

  let!(:merge_request2) do
    merge_requests.create!(
      target_project_id: project.id,
      target_branch: 'master',
      source_branch: 'feature',
      source_project_id: project.id
    )
  end

  let!(:deployment1) do
    deployments.create!(
      iid: 1,
      environment_id: environment1.id,
      project_id: project.id,
      status: 1,
      ref: merge_request1.source_branch,
      sha: '0000000000000000000000000000000000000000',
      tag: false
    )
  end

  let!(:deployment2) do
    deployments.create!(
      iid: 2,
      environment_id: environment2.id,
      project_id: project.id,
      status: 1,
      ref: merge_request2.source_branch,
      sha: '0000000000000000000000000000000000000000',
      tag: false
    )
  end

  let!(:deployment_merge_request1) do
    deployment_merge_requests.create!(deployment_id: deployment1.id, merge_request_id: merge_request1.id,
      environment_id: environment1.id)
  end

  let!(:deployment_merge_request2) do
    deployment_merge_requests.create!(deployment_id: deployment2.id, merge_request_id: merge_request1.id,
      environment_id: environment2.id)
  end

  let!(:deployment_merge_request3) do
    deployment_merge_requests.create!(deployment_id: deployment1.id, merge_request_id: merge_request2.id,
      environment_id: environment1.id)
  end

  let!(:deployment_merge_request4) do
    deployment_merge_requests.create!(deployment_id: deployment2.id, merge_request_id: merge_request2.id,
      environment_id: environment2.id)
  end

  around do |example|
    connection.add_column :deployment_merge_requests, :deployment_id_convert_to_bigint, :bigint, if_not_exists: true
    connection.add_column :deployment_merge_requests, :merge_request_id_convert_to_bigint, :bigint, if_not_exists: true
    connection.add_column :deployment_merge_requests, :environment_id_convert_to_bigint, :bigint, if_not_exists: true

    example.run

    connection.remove_column :deployment_merge_requests, :deployment_id_convert_to_bigint, :bigint, if_exists: true
    connection.remove_column :deployment_merge_requests, :merge_request_id_convert_to_bigint, :bigint, if_exists: true
    connection.remove_column :deployment_merge_requests, :environment_id_convert_to_bigint, :bigint, if_exists: true
  end

  describe '#perform' do
    it 'backfills bigint columns', :aggregate_failures do
      migration.perform

      expect(deployment_merge_request1.reload).to have_attributes(deployment_id_convert_to_bigint: deployment1.id,
        merge_request_id_convert_to_bigint: merge_request1.id, environment_id_convert_to_bigint: environment1.id)

      expect(deployment_merge_request2.reload).to have_attributes(deployment_id_convert_to_bigint: deployment2.id,
        merge_request_id_convert_to_bigint: merge_request1.id, environment_id_convert_to_bigint: environment2.id)

      expect(deployment_merge_request3.reload).to have_attributes(deployment_id_convert_to_bigint: deployment1.id,
        merge_request_id_convert_to_bigint: merge_request2.id, environment_id_convert_to_bigint: environment1.id)

      expect(deployment_merge_request4.reload).to have_attributes(deployment_id_convert_to_bigint: deployment2.id,
        merge_request_id_convert_to_bigint: merge_request2.id, environment_id_convert_to_bigint: environment2.id)
    end
  end
end
