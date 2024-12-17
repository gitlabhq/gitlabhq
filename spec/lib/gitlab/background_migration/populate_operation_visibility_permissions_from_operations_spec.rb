# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateOperationVisibilityPermissionsFromOperations do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:project_features) { table(:project_features) }
  let(:projects) { table(:projects) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:namespace) { namespaces.create!(name: 'user', path: 'user', organization_id: organization.id) }

  let(:proj_namespace1) { create_project_namespace('proj1') }
  let(:proj_namespace2) { create_project_namespace('proj2') }
  let(:proj_namespace3) { create_project_namespace('proj3') }

  let(:project1) { create_project('test1', proj_namespace1) }
  let(:project2) { create_project('test2', proj_namespace2) }
  let(:project3) { create_project('test3', proj_namespace3) }

  let!(:record1) { create_project_feature(project1) }
  let!(:record2) { create_project_feature(project2, 20) }
  let!(:record3) { create_project_feature(project3) }

  let(:sub_batch_size) { 2 }
  let(:start_id) { record1.id }
  let(:end_id) { record3.id }
  let(:batch_table) { :project_features }
  let(:batch_column) { :id }
  let(:pause_ms) { 1 }
  let(:connection) { ApplicationRecord.connection }

  let(:job) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: batch_table,
      batch_column: batch_column,
      sub_batch_size: sub_batch_size,
      pause_ms: pause_ms,
      connection: connection
    )
  end

  subject(:perform) { job.perform }

  it 'updates all project settings records from their operations_access_level', :aggregate_failures do
    perform

    expect_project_features_match_operations_access_level(record1)
    expect_project_features_match_operations_access_level(record2)
    expect_project_features_match_operations_access_level(record3)
  end

  private

  def expect_project_features_match_operations_access_level(record)
    record.reload
    expect(record.monitor_access_level).to eq(record.operations_access_level)
    expect(record.infrastructure_access_level).to eq(record.operations_access_level)
    expect(record.feature_flags_access_level).to eq(record.operations_access_level)
    expect(record.environments_access_level).to eq(record.operations_access_level)
  end

  def create_project_namespace(name)
    namespaces.create!(
      name: name,
      path: name,
      type: 'Project',
      parent_id: namespace.id,
      organization_id: organization.id
    )
  end

  def create_project(proj_name, proj_namespace)
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: proj_namespace.id,
      name: proj_name,
      path: proj_name,
      organization_id: organization.id
    )
  end

  def create_project_feature(project, operations_access_level = 10)
    project_features.create!(
      project_id: project.id,
      pages_access_level: 10,
      operations_access_level: operations_access_level
    )
  end
end
