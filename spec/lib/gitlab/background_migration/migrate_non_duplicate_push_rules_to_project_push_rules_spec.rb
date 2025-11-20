# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateNonDuplicatePushRulesToProjectPushRules,
  feature_category: :source_code_management do
  let(:push_rules_table) { table(:push_rules) }
  let(:project_push_rules_table) { table(:project_push_rules) }
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }
  let(:organizations_table) { table(:organizations) }
  let(:connection) { ApplicationRecord.connection }

  let!(:organization) { organizations_table.create!(name: "Organization", path: "organization") }

  let!(:project_namespace) do
    namespaces_table.create!(
      name: 'project',
      path: 'project',
      type: 'Project',
      organization_id: organization.id
    )
  end

  let!(:group_namespace) do
    namespaces_table.create!(
      name: 'group',
      path: 'group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:project) do
    projects_table.create!(
      name: 'test_project',
      path: 'test_project',
      namespace_id: group_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:push_rule_attributes) do
    {
      commit_message_regex: 'Default commit message',
      deny_delete_tag: false,
      author_email_regex: 'test@test.com',
      member_check: false,
      file_name_regex: 'filename.png',
      max_file_size: 120,
      prevent_secrets: true,
      branch_name_regex: 'branch_name',
      reject_unsigned_commits: true,
      commit_committer_check: true,
      commit_message_negative_regex: 'commit_negative_3',
      reject_non_dco_commits: false,
      commit_committer_name_check: true
    }
  end

  let(:args) do
    min, max = push_rules_table.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min,
      end_id: max,
      batch_table: 'push_rules',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**args).perform }

  describe '#perform' do
    # Disable triggers to test migration logic in isolation
    around do |example|
      connection.execute('DROP TRIGGER IF EXISTS trigger_sync_project_push_rules_insert_update ON push_rules')
      connection.execute('DROP TRIGGER IF EXISTS trigger_sync_project_push_rules_delete ON push_rules')

      example.run

      # Recreate triggers after test
      connection.execute(<<~SQL)
        CREATE TRIGGER trigger_sync_project_push_rules_insert_update
        AFTER INSERT OR UPDATE ON push_rules
        FOR EACH ROW
        EXECUTE FUNCTION sync_project_push_rules_on_insert_update();
      SQL

      connection.execute(<<~SQL)
        CREATE TRIGGER trigger_sync_project_push_rules_delete
        AFTER DELETE ON push_rules
        FOR EACH ROW
        EXECUTE FUNCTION sync_project_push_rules_on_delete();
      SQL
    end

    context 'when push rule is associated with a project' do
      let!(:push_rule) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          **push_rule_attributes
        )
      end

      it 'creates a project_push_rules record with synced push_rule ID' do
        expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

        project_push_rule = project_push_rules_table.last
        expect(project_push_rule.id).to eq(push_rule.id)
        expect(project_push_rule.project_id).to eq(project.id)
        expect(project_push_rule.commit_message_regex).to eq(push_rule.commit_message_regex)
        expect(project_push_rule.max_file_size).to eq(push_rule.max_file_size)
      end

      it 'copies all push rule attributes correctly', :freeze_time do
        perform_migration

        project_push_rule = project_push_rules_table.last
        expect(project_push_rule.deny_delete_tag).to eq(push_rule.deny_delete_tag)
        expect(project_push_rule.author_email_regex).to eq(push_rule.author_email_regex)
        expect(project_push_rule.member_check).to eq(push_rule.member_check)
        expect(project_push_rule.file_name_regex).to eq(push_rule.file_name_regex)
        expect(project_push_rule.prevent_secrets).to eq(push_rule.prevent_secrets)
        expect(project_push_rule.branch_name_regex).to eq(push_rule.branch_name_regex)
        expect(project_push_rule.reject_unsigned_commits).to eq(push_rule.reject_unsigned_commits)
        expect(project_push_rule.commit_committer_check).to eq(push_rule.commit_committer_check)
        expect(project_push_rule.commit_message_negative_regex).to eq(push_rule.commit_message_negative_regex)
        expect(project_push_rule.reject_non_dco_commits).to eq(push_rule.reject_non_dco_commits)
        expect(project_push_rule.commit_committer_name_check).to eq(push_rule.commit_committer_name_check)
        expect(project_push_rule.created_at).to eq(push_rule.created_at)
        expect(project_push_rule.updated_at).to eq(push_rule.updated_at)
      end
    end

    context 'when push rule has project_id and organization_id set' do
      let!(:push_rule) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          organization_id: organization.id,
          **push_rule_attributes
        )
      end

      it 'creates a project_push_rules record with synced push_rule ID' do
        expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

        project_push_rule = project_push_rules_table.last
        expect(project_push_rule.id).to eq(push_rule.id)
        expect(project_push_rule.project_id).to eq(project.id)
        expect(project_push_rule.commit_message_regex).to eq(push_rule.commit_message_regex)
        expect(project_push_rule.max_file_size).to eq(push_rule.max_file_size)
      end
    end

    context 'when push rule has is_sample set to true' do
      let!(:push_rule) do
        push_rules_table.create!(
          is_sample: true,
          **push_rule_attributes
        )
      end

      it 'does not create a project_push_rules record' do
        expect { perform_migration }.not_to change { project_push_rules_table.count }
      end
    end

    context 'when push rule has organization_id alone set' do
      let!(:push_rule) do
        push_rules_table.create!(
          is_sample: false,
          organization_id: organization.id,
          **push_rule_attributes
        )
      end

      it 'does not create a project_push_rules record' do
        expect { perform_migration }.not_to change { project_push_rules_table.count }
      end
    end

    context 'when push rule is not associated with a project' do
      let!(:push_rule) do
        push_rules_table.create!(
          is_sample: false,
          **push_rule_attributes
        )
      end

      it 'does not create a project_push_rules record' do
        expect { perform_migration }.not_to change { project_push_rules_table.count }
      end
    end

    context 'when project_push_rules record already exists' do
      let!(:push_rule) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          **push_rule_attributes
        )
      end

      let!(:existing_project_push_rule) do
        project_push_rules_table.create!(
          id: push_rule.id,
          project_id: project.id,
          commit_message_regex: 'Old message',
          created_at: push_rule.created_at,
          updated_at: push_rule.updated_at,
          **push_rule_attributes.except(:commit_message_regex)
        )
      end

      it 'does not create a duplicate record' do
        expect { perform_migration }.not_to change { project_push_rules_table.count }
      end

      it 'does not modify the existing record' do
        original_regex = existing_project_push_rule.commit_message_regex

        perform_migration

        existing_project_push_rule.reload
        expect(existing_project_push_rule.commit_message_regex).to eq(original_regex)
      end
    end

    context 'when multiple push rules are associated with different projects' do
      let!(:another_project_namespace) do
        namespaces_table.create!(
          name: 'another_project',
          path: 'another_project',
          type: 'Project',
          organization_id: organization.id
        )
      end

      let!(:another_project) do
        projects_table.create!(
          name: 'another_project',
          path: 'another_project',
          namespace_id: group_namespace.id,
          project_namespace_id: another_project_namespace.id,
          organization_id: organization.id
        )
      end

      let!(:push_rule1) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          **push_rule_attributes
        )
      end

      let!(:push_rule2) do
        push_rules_table.create!(
          project_id: another_project.id,
          is_sample: false,
          **push_rule_attributes.merge(commit_message_regex: 'Different message')
        )
      end

      it 'creates project_push_rules records for both projects' do
        expect { perform_migration }.to change { project_push_rules_table.count }.by(2)

        project_push_rule1 = project_push_rules_table.find_by(id: push_rule1.id)
        project_push_rule2 = project_push_rules_table.find_by(id: push_rule2.id)

        expect(project_push_rule1.project_id).to eq(project.id)
        expect(project_push_rule1.commit_message_regex).to eq('Default commit message')

        expect(project_push_rule2.project_id).to eq(another_project.id)
        expect(project_push_rule2.commit_message_regex).to eq('Different message')
      end
    end

    context 'when duplicate push rules exist for the same project' do
      let!(:push_rule1) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          **push_rule_attributes.merge(commit_message_regex: 'First rule')
        )
      end

      let!(:push_rule2) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          **push_rule_attributes.merge(commit_message_regex: 'Second rule')
        )
      end

      it 'does not migrate any push rules for that project' do
        expect { perform_migration }.not_to change { project_push_rules_table.count }
      end

      it 'skips both duplicate push rules' do
        perform_migration

        expect(project_push_rules_table.find_by(id: push_rule1.id)).to be_nil
        expect(project_push_rules_table.find_by(id: push_rule2.id)).to be_nil
      end
    end

    context 'when some projects have duplicates and others do not' do
      let!(:another_project_namespace) do
        namespaces_table.create!(
          name: 'another_project',
          path: 'another_project',
          type: 'Project',
          organization_id: organization.id
        )
      end

      let!(:another_project) do
        projects_table.create!(
          name: 'another_project',
          path: 'another_project',
          namespace_id: group_namespace.id,
          project_namespace_id: another_project_namespace.id,
          organization_id: organization.id
        )
      end

      let!(:non_duplicate_push_rule) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          **push_rule_attributes
        )
      end

      let!(:duplicate_push_rule1) do
        push_rules_table.create!(
          project_id: another_project.id,
          is_sample: false,
          **push_rule_attributes.merge(commit_message_regex: 'Duplicate 1')
        )
      end

      let!(:duplicate_push_rule2) do
        push_rules_table.create!(
          project_id: another_project.id,
          is_sample: false,
          **push_rule_attributes.merge(commit_message_regex: 'Duplicate 2')
        )
      end

      it 'migrates only non-duplicate push rules' do
        expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

        expect(project_push_rules_table.find_by(id: non_duplicate_push_rule.id)).to be_present

        expect(project_push_rules_table.find_by(id: duplicate_push_rule1.id)).to be_nil
        expect(project_push_rules_table.find_by(id: duplicate_push_rule2.id)).to be_nil
      end
    end
  end
end
