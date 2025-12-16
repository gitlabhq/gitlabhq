# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateDuplicatePushRulesToProjectPushRules,
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
    min, max = projects_table.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min,
      end_id: max,
      batch_table: 'projects',
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

    context 'when on GitLab.com_except_jh?' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
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

        it 'migrates only the push rule with the lowest id: order(:id)' do
          expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

          project_push_rule = project_push_rules_table.find_by(project_id: project.id)
          expect(project_push_rule.id).to eq(push_rule1.id)
          expect(project_push_rule.commit_message_regex).to eq('First rule')
        end

        it 'copies all attributes correctly' do
          perform_migration

          project_push_rule = project_push_rules_table.find_by(project_id: project.id)
          expect(project_push_rule.deny_delete_tag).to eq(push_rule1.deny_delete_tag)
          expect(project_push_rule.author_email_regex).to eq(push_rule1.author_email_regex)
          expect(project_push_rule.max_file_size).to eq(push_rule1.max_file_size)
        end
      end

      context 'when project already has a project_push_rule' do
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

        let!(:existing_project_push_rule) do
          project_push_rules_table.create!(
            id: push_rule2.id,
            project_id: project.id,
            commit_message_regex: 'Existing rule',
            created_at: push_rule2.created_at,
            updated_at: push_rule2.updated_at,
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

      context 'when multiple duplicates exist for the same project' do
        let!(:push_rule1) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes.merge(commit_message_regex: 'Rule 1')
          )
        end

        let!(:push_rule2) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes.merge(commit_message_regex: 'Rule 2')
          )
        end

        let!(:push_rule3) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes.merge(commit_message_regex: 'Rule 3')
          )
        end

        it 'migrates only the one with the lowest id' do
          expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

          project_push_rule = project_push_rules_table.find_by(project_id: project.id)
          expect(project_push_rule.id).to eq(push_rule1.id)
          expect(project_push_rule.commit_message_regex).to eq('Rule 1')
        end
      end

      context 'when mix of duplicates and non-duplicates exist' do
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

        # Non-duplicate (should be skipped)
        let!(:non_duplicate_push_rule) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes
          )
        end

        # Duplicates for another_project (should be migrated)
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

        it 'migrates only duplicates and skips non-duplicates' do
          expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

          # Non-duplicate is not migrated
          expect(project_push_rules_table.find_by(project_id: project.id)).to be_nil

          # Duplicate is migrated (lowest ID)
          another_project_rule = project_push_rules_table.find_by(project_id: another_project.id)
          expect(another_project_rule.id).to eq(duplicate_push_rule1.id)
          expect(another_project_rule.commit_message_regex).to eq('Duplicate 1')
        end
      end

      context 'when push rules have no project_id' do
        let!(:push_rule1) do
          push_rules_table.create!(
            project_id: nil,
            is_sample: false,
            **push_rule_attributes
          )
        end

        let!(:push_rule2) do
          push_rules_table.create!(
            project_id: nil,
            is_sample: false,
            **push_rule_attributes
          )
        end

        it 'does not migrate any push rules' do
          expect { perform_migration }.not_to change { project_push_rules_table.count }
        end
      end

      context 'when push rules are samples' do
        let!(:push_rule1) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: true,
            **push_rule_attributes
          )
        end

        let!(:push_rule2) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: true,
            **push_rule_attributes
          )
        end

        it 'does not migrate any push rules' do
          expect { perform_migration }.not_to change { project_push_rules_table.count }
        end
      end
    end

    context 'when not on GitLab.com_except_jh?' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
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

        it 'migrates exactly one push rule for the project' do
          expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

          project_push_rule = project_push_rules_table.find_by(project_id: project.id)
          expect(project_push_rule).to be_present
          expect(project_push_rule.project_id).to eq(project.id)
        end

        it 'migrates one of the duplicate push rules' do
          perform_migration

          project_push_rule = project_push_rules_table.find_by(project_id: project.id)
          expect([push_rule1.id, push_rule2.id]).to include(project_push_rule.id)
        end

        it 'copies all attributes correctly' do
          perform_migration

          project_push_rule = project_push_rules_table.find_by(project_id: project.id)
          source_push_rule = push_rules_table.find(project_push_rule.id)

          expect(project_push_rule.deny_delete_tag).to eq(source_push_rule.deny_delete_tag)
          expect(project_push_rule.author_email_regex).to eq(source_push_rule.author_email_regex)
          expect(project_push_rule.max_file_size).to eq(source_push_rule.max_file_size)
          expect(project_push_rule.commit_message_regex).to eq(source_push_rule.commit_message_regex)
        end
      end

      context 'when project already has a project_push_rule' do
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

        let!(:existing_project_push_rule) do
          project_push_rules_table.create!(
            id: push_rule2.id,
            project_id: project.id,
            commit_message_regex: 'Existing rule',
            created_at: push_rule2.created_at,
            updated_at: push_rule2.updated_at,
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

      context 'when multiple duplicates exist for the same project' do
        let!(:push_rule1) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes.merge(commit_message_regex: 'Rule 1')
          )
        end

        let!(:push_rule2) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes.merge(commit_message_regex: 'Rule 2')
          )
        end

        let!(:push_rule3) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes.merge(commit_message_regex: 'Rule 3')
          )
        end

        it 'migrates exactly one push rule' do
          expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

          project_push_rule = project_push_rules_table.find_by(project_id: project.id)
          expect(project_push_rule).to be_present
        end

        it 'migrates one of the three duplicates' do
          perform_migration

          project_push_rule = project_push_rules_table.find_by(project_id: project.id)
          all_ids = [push_rule1.id, push_rule2.id, push_rule3.id]
          expect(all_ids).to include(project_push_rule.id)
        end
      end

      context 'when mix of duplicates and non-duplicates exist' do
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

        # Non-duplicate (should be skipped)
        let!(:non_duplicate_push_rule) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes
          )
        end

        # Duplicates for another_project (should be migrated)
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

        it 'migrates only duplicates and skips non-duplicates' do
          expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

          # Non-duplicate is not migrated
          expect(project_push_rules_table.find_by(project_id: project.id)).to be_nil

          # Duplicate is migrated
          another_project_rule = project_push_rules_table.find_by(project_id: another_project.id)
          expect(another_project_rule).to be_present
        end
      end

      context 'when push rules have no project_id' do
        let!(:push_rule1) do
          push_rules_table.create!(
            project_id: nil,
            is_sample: false,
            **push_rule_attributes
          )
        end

        let!(:push_rule2) do
          push_rules_table.create!(
            project_id: nil,
            is_sample: false,
            **push_rule_attributes
          )
        end

        it 'does not migrate any push rules' do
          expect { perform_migration }.not_to change { project_push_rules_table.count }
        end
      end

      context 'when push rules are samples' do
        let!(:push_rule1) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: true,
            **push_rule_attributes
          )
        end

        let!(:push_rule2) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: true,
            **push_rule_attributes
          )
        end

        it 'does not migrate any push rules' do
          expect { perform_migration }.not_to change { project_push_rules_table.count }
        end
      end

      context 'when handling RecordNotUnique' do
        let!(:push_rule1) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes
          )
        end

        let!(:push_rule2) do
          push_rules_table.create!(
            project_id: project.id,
            is_sample: false,
            **push_rule_attributes
          )
        end

        before do
          allow(described_class::ProjectPushRule).to receive(:insert).and_raise(ActiveRecord::RecordNotUnique)
        end

        it 'handles the exception gracefully and continues' do
          expect { perform_migration }.not_to change { project_push_rules_table.count }
        end
      end
    end
  end
end
