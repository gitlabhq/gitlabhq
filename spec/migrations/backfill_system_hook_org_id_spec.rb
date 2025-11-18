# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillSystemHookOrgId, feature_category: :webhooks do
  let(:web_hooks) { table(:web_hooks) }
  let(:organizations) { table(:organizations) }

  let(:organization_default) { organizations.create!(name: 'Default', path: 'default') }
  let(:organization_custom) { organizations.create!(name: 'Custom', path: 'custom') }
  let(:first_organization) { organizations.all.first }
  let(:last_organization) { organizations.all.last }
  let(:organization_default_id) { organization_default.id }
  let(:organization_custom_id) { organization_custom.id }

  let(:hook_params) do
    {
      created_at: Time.current,
      updated_at: Time.current,
      push_events: true,
      issues_events: false,
      merge_requests_events: false,
      tag_push_events: false
    }
  end

  before do
    ApplicationRecord.connection.execute(
      'ALTER TABLE web_hooks DROP CONSTRAINT IF EXISTS check_95b85171f8;')
  end

  after do
    ApplicationRecord.connection.execute(
      'ALTER TABLE web_hooks ADD CONSTRAINT check_95b85171f8 ' \
        'CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1));'
    )
  end

  context 'when SystemHooks are present' do
    let!(:system_hook_with_org_id) do
      ActiveRecord::Base.connection.execute(
        "INSERT INTO web_hooks (name, type, organization_id, created_at, updated_at)
        VALUES ('test hook 1', 'SystemHook', #{organization_default_id}, NOW(), NOW())
        RETURNING id"
      ).first['id']
    end

    let!(:system_hook_without_org_id) do
      ActiveRecord::Base.connection.execute(
        "INSERT INTO web_hooks (name, type, organization_id, created_at, updated_at)
        VALUES ('test hook 2', 'SystemHook', NULL, NOW(), NOW())
        RETURNING id"
      ).first['id']
    end

    let(:system_hook_with_org) { web_hooks.find(system_hook_with_org_id) }
    let(:system_hook_without_org) { web_hooks.find(system_hook_without_org_id) }

    it 'backfills the nil organization_id, ignores the existing organization_id' do
      migrate!

      expect(system_hook_with_org.reload.organization_id).to eq(organization_default.id)
      expect(system_hook_without_org.reload.organization_id).to eq(first_organization.id)
    end
  end

  context 'when GroupHooks and ProjectHooks are present' do
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:users) { table(:users) }

    let(:user) do
      users.create!(
        email: 'test@example.com',
        username: 'testuser',
        name: 'Test User',
        projects_limit: 10,
        organization_id: organization_custom_id
      )
    end

    let(:group) do
      namespaces.create!(
        name: 'group',
        path: 'group',
        type: Group,
        organization_id: organization_custom_id,
        owner_id: user.id
      )
    end

    let(:project_namespace) do
      namespaces.create!(
        name: 'project',
        path: 'project',
        type: 'Project',
        parent_id: group.id,
        organization_id: organization_custom_id
      )
    end

    let(:project) do
      projects.create!(
        name: 'project',
        path: 'project',
        namespace_id: group.id,
        creator_id: user.id,
        project_namespace_id: project_namespace.id,
        visibility_level: 10,
        organization_id: organization_custom_id
      )
    end

    let(:group_id) { group.id }
    let(:project_id) { project.id }

    let!(:group_hook_id) do
      ActiveRecord::Base.connection.execute(
        "INSERT INTO web_hooks (name, type, group_id, created_at, updated_at)
        VALUES ('test hook 1', 'GroupHook', #{group_id}, NOW(), NOW())
        RETURNING id"
      ).first['id']
    end

    let!(:project_hook_id) do
      ActiveRecord::Base.connection.execute(
        "INSERT INTO web_hooks (name, type, project_id, created_at, updated_at)
        VALUES ('test hook 2', 'ProjectHook', #{project_id}, NOW(), NOW())
        RETURNING id"
      ).first['id']
    end

    let(:group_hook) { web_hooks.find(group_hook_id) }
    let(:project_hook) { web_hooks.find(project_hook_id) }

    it 'ignores the nil `organization_id`' do
      migrate!

      expect(group_hook.reload.organization_id).to be_nil
      expect(project_hook.reload.organization_id).to be_nil
    end
  end
end
