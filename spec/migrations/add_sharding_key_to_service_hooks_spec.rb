# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddShardingKeyToServiceHooks, feature_category: :webhooks do
  let(:users) { table(:users) }
  let(:web_hooks) { table(:web_hooks) }
  let(:integrations) { table(:integrations) }
  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let(:existing_organization) { organizations.create!(name: 'Custom', path: 'custom') }

  let(:group) do
    namespaces.create!(
      name: 'bar',
      path: 'bar',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let(:existing_group) do
    namespaces.create!(
      name: 'boo',
      path: 'boo',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:project) { create_project('baz', organization, group) }
  let!(:existing_project) { create_project('boo', existing_organization, existing_group) }

  let(:integration_project_level) { integrations.create!(project_id: project.id) }
  let(:integration_project_level_2) { integrations.create!(project_id: existing_project.id) }
  let(:integration_group_level) { integrations.create!(group_id: group.id) }
  let(:integration_group_level_2) { integrations.create!(group_id: existing_group.id) }
  let(:integration_instance_level) { integrations.create!(organization_id: organization.id) }
  let(:integration_instance_level_2) { integrations.create!(organization_id: existing_organization.id) }

  describe 'backfilling sharding keys' do
    context 'when ServiceHooks have no sharding key' do
      before do
        create_service_hook('test hook 1', integration_project_level.id)
        create_service_hook('test hook 2', integration_group_level.id)
        create_service_hook('test hook 3', integration_instance_level.id)
      end

      it 'backfills the sharding key based on integration level' do
        migrate!

        expect_sharding_keys(
          'test hook 1' => { project_id: project.id, group_id: nil, organization_id: nil },
          'test hook 2' => { project_id: nil, group_id: group.id, organization_id: nil },
          'test hook 3' => { project_id: nil, group_id: nil, organization_id: organization.id }
        )
      end
    end

    context 'when ServiceHooks already have a sharding key' do
      before do
        create_service_hook_with_sharding('test hook 4', existing_project.id, integration_project_level_2.id,
          :project_id)
        create_service_hook_with_sharding('test hook 5', existing_group.id, integration_group_level_2.id, :group_id)
        create_service_hook_with_sharding('test hook 6', existing_organization.id, integration_instance_level_2.id,
          :organization_id)
      end

      it 'preserves existing sharding keys' do
        migrate!

        expect_sharding_keys(
          'test hook 4' => { project_id: existing_project.id, group_id: nil, organization_id: nil },
          'test hook 5' => { project_id: nil, group_id: existing_group.id, organization_id: nil },
          'test hook 6' => { project_id: nil, group_id: nil, organization_id: existing_organization.id }
        )
      end
    end

    context 'when webhooks are not ServiceHooks' do
      before do
        create_non_service_hook('project hook', 'ProjectHook', project.id, :project_id)
        create_non_service_hook('group hook', 'GroupHook', group.id, :group_id)
        create_non_service_hook('system hook', 'SystemHook', organization.id, :organization_id)
      end

      it 'does not modify non-ServiceHook webhooks' do
        migrate!

        project_hook = web_hooks.find_by(name: 'project hook')
        group_hook = web_hooks.find_by(name: 'group hook')
        system_hook = web_hooks.find_by(name: 'system hook')

        expect(project_hook.project_id).to eq(project.id)
        expect(project_hook.group_id).to be_nil
        expect(project_hook.organization_id).to be_nil

        expect(group_hook.project_id).to be_nil
        expect(group_hook.group_id).to eq(group.id)
        expect(group_hook.organization_id).to be_nil

        expect(system_hook.project_id).to be_nil
        expect(system_hook.group_id).to be_nil
        expect(system_hook.organization_id).to eq(organization.id)
      end
    end
  end

  private

  def create_project(name, organization, namespace)
    projects.create!(
      name: name,
      path: name,
      organization_id: organization.id,
      namespace_id: namespace.id,
      project_namespace_id: namespace.id
    )
  end

  def create_service_hook(name, integration_id)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO web_hooks (name, type, integration_id, created_at, updated_at)
       VALUES ('#{name}', 'ServiceHook', #{integration_id}, NOW(), NOW())"
    )
  end

  def create_service_hook_with_sharding(name, sharding_id, integration_id, sharding_column)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO web_hooks (name, type, #{sharding_column}, integration_id, created_at, updated_at)
       VALUES ('#{name}', 'ServiceHook', #{sharding_id}, #{integration_id}, NOW(), NOW())"
    )
  end

  def create_non_service_hook(name, type, sharding_id, sharding_column)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO web_hooks (name, type, #{sharding_column}, created_at, updated_at)
        VALUES ('#{name}', '#{type}', #{sharding_id}, NOW(), NOW())"
    )
  end

  def expect_sharding_keys(expectations)
    expectations.each do |hook_name, expected_keys|
      hook = ServiceHook.find_by(name: hook_name)

      expect(hook.project_id).to eq(expected_keys[:project_id])
      expect(hook.group_id).to eq(expected_keys[:group_id])
      expect(hook.organization_id).to eq(expected_keys[:organization_id])
    end
  end
end
