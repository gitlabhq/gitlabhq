# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSecretPushProtectionEnabled, feature_category: :secret_detection do
  let(:project_security_settings) { table(:project_security_settings) }
  let!(:connection) { table(:project_security_settings).connection }
  let!(:starting_id) { table(:project_security_settings).pluck(:project_id).min }
  let!(:end_id) { table(:project_security_settings).pluck(:project_id).max }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :project_security_settings,
      batch_column: :project_id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: connection,
      job_arguments: []
    )
  end

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let!(:namespace) do
    namespaces
      .create!(name: 'root-group', path: 'root', type: 'Group', organization_id: organization.id)
      .tap do |new_group|
        new_group.update!(traversal_ids: [new_group.id])
      end
  end

  let!(:group_1) do
    namespaces.create!(name: 'random-group', path: 'random', type: 'Group', organization_id: organization.id)
  end

  let!(:group_2) do
    namespaces.create!(name: 'random-group-2', path: 'random-2', type: 'Group', organization_id: organization.id)
  end

  let!(:project_1) do
    projects.create!(
      organization_id: organization.id,
      namespace_id: group_1.id,
      project_namespace_id: group_1.id,
      name: 'test project',
      path: 'test-project'
    )
  end

  let!(:project_2) do
    projects.create!(
      organization_id: organization.id,
      namespace_id: group_2.id,
      project_namespace_id: group_2.id,
      name: 'test project-2',
      path: 'test-project-2'
    )
  end

  before do
    project_security_settings.create!(project_id: project_1.id, pre_receive_secret_detection_enabled: true,
      secret_push_protection_enabled: false)
    project_security_settings.create!(project_id: project_2.id, pre_receive_secret_detection_enabled: false,
      secret_push_protection_enabled: false)
  end

  it 'performs without error' do
    expect { migration.perform }.not_to raise_error
  end

  it 'updates secret_push_protection_enabled to match pre_receive_secret_detection_enabled' do
    migration.perform

    security_settings_1 = project_security_settings.find_by(project_id: project_1.id)
    security_settings_2 = project_security_settings.find_by(project_id: project_2.id)
    expect(security_settings_1.secret_push_protection_enabled).to be(true)
    expect(security_settings_2.secret_push_protection_enabled).to be(false)
  end
end
