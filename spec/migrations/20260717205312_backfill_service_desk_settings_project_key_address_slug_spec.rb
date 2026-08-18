# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillServiceDeskSettingsProjectKeyAddressSlug, migration: :gitlab_main, feature_category: :service_desk do
  let(:service_desk_settings) { table(:service_desk_settings) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:group) do
    table(:namespaces).create!(name: 'group', path: 'group', organization_id: organization.id)
  end

  let!(:project_with_key) { create_project('with-key') }
  let!(:project_without_key) { create_project('without-key') }
  let!(:project_backfilled) { create_project('already-backfilled') }

  let!(:setting_with_key) do
    service_desk_settings.create!(project_id: project_with_key.id, project_key: 'mykey')
  end

  let!(:setting_without_key) do
    service_desk_settings.create!(project_id: project_without_key.id, project_key: nil)
  end

  let!(:setting_backfilled) do
    service_desk_settings.create!(
      project_id: project_backfilled.id, project_key: 'otherkey', project_key_address_slug: 'stale-value'
    )
  end

  describe '#up' do
    it 'backfills the composite slug for settings with a project_key' do
      migrate!

      expect(setting_with_key.reload.project_key_address_slug).to eq('group-with-key-mykey')
      expect(setting_backfilled.reload.project_key_address_slug).to eq('group-already-backfilled-otherkey')
      expect(setting_without_key.reload.project_key_address_slug).to be_nil
    end
  end

  def create_project(path)
    project_namespace = table(:namespaces).create!(
      name: path, path: path, type: 'Project', parent_id: group.id, organization_id: organization.id
    )

    project = table(:projects).create!(
      name: path,
      path: path,
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )

    table(:routes).create!(
      source_type: 'Project',
      source_id: project.id,
      path: "group/#{path}",
      namespace_id: project_namespace.id
    )

    project
  end
end
