# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResetDuoRemoteFlowsEnabledFalseValues, feature_category: :duo_agent_platform do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_settings) { table(:project_settings) }

  let!(:organization) { organizations.create!(name: 'Organization', path: 'organization') }
  let!(:group_namespace) do
    namespaces.create!(
      name: 'test-group',
      path: 'test-group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:project1) { create_project('project1', group_namespace) }
  let!(:project2) { create_project('project2', group_namespace) }
  let!(:project3) { create_project('project3', group_namespace) }

  let!(:setting_with_false) { project_settings.create!(project_id: project1.id, duo_remote_flows_enabled: false) }
  let!(:setting_with_true) { project_settings.create!(project_id: project2.id, duo_remote_flows_enabled: true) }
  let!(:setting_with_nil) { project_settings.create!(project_id: project3.id, duo_remote_flows_enabled: nil) }

  let(:start_id) { project_settings.minimum(:project_id) }
  let(:end_id) { project_settings.maximum(:project_id) }

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :project_settings,
      batch_column: :project_id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'updates false values to nil and leaves other values unchanged' do
    expect { migration.perform }
      .to change { setting_with_false.reload.duo_remote_flows_enabled }
            .from(false).to(nil)
            .and not_change { setting_with_true.reload.duo_remote_flows_enabled }
                   .and not_change { setting_with_nil.reload.duo_remote_flows_enabled }
  end

  def create_project(name, group)
    project_namespace = namespaces.create!(
      name: name,
      path: name,
      type: 'Project',
      organization_id: organization.id
    )

    projects.create!(
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id,
      name: name,
      path: name
    )
  end
end
