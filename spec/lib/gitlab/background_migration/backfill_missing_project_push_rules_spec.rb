# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMissingProjectPushRules,
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
    around do |example|
      connection.execute('DROP TRIGGER IF EXISTS trigger_sync_project_push_rules_insert_update ON push_rules')
      connection.execute('DROP TRIGGER IF EXISTS trigger_sync_project_push_rules_delete ON push_rules')

      example.run

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

    context 'when push rule is missing from project_push_rules' do
      let!(:push_rule) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          **push_rule_attributes
        )
      end

      it 'creates a project_push_rules record' do
        expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

        project_push_rule = project_push_rules_table.last
        expect(project_push_rule.id).to eq(push_rule.id)
        expect(project_push_rule.project_id).to eq(project.id)
      end

      it 'copies all push rule attributes correctly' do
        perform_migration

        project_push_rule = project_push_rules_table.last
        expect(project_push_rule.commit_message_regex).to eq(push_rule.commit_message_regex)
        expect(project_push_rule.deny_delete_tag).to eq(push_rule.deny_delete_tag)
        expect(project_push_rule.author_email_regex).to eq(push_rule.author_email_regex)
        expect(project_push_rule.member_check).to eq(push_rule.member_check)
        expect(project_push_rule.file_name_regex).to eq(push_rule.file_name_regex)
        expect(project_push_rule.max_file_size).to eq(push_rule.max_file_size)
        expect(project_push_rule.prevent_secrets).to eq(push_rule.prevent_secrets)
        expect(project_push_rule.branch_name_regex).to eq(push_rule.branch_name_regex)
        expect(project_push_rule.reject_unsigned_commits).to eq(push_rule.reject_unsigned_commits)
        expect(project_push_rule.commit_committer_check).to eq(push_rule.commit_committer_check)
        expect(project_push_rule.commit_message_negative_regex).to eq(push_rule.commit_message_negative_regex)
        expect(project_push_rule.reject_non_dco_commits).to eq(push_rule.reject_non_dco_commits)
        expect(project_push_rule.commit_committer_name_check).to eq(push_rule.commit_committer_name_check)
      end
    end

    context 'when push rule already exists in project_push_rules' do
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
          commit_message_regex: 'Existing message',
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

    context 'when push rule has no project_id' do
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

    context 'when some push rules are missing and some already exist' do
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

      let!(:missing_push_rule) do
        push_rules_table.create!(
          project_id: project.id,
          is_sample: false,
          **push_rule_attributes
        )
      end

      let!(:existing_push_rule) do
        push_rules_table.create!(
          project_id: another_project.id,
          is_sample: false,
          **push_rule_attributes.merge(commit_message_regex: 'Another message')
        )
      end

      let!(:existing_project_push_rule) do
        project_push_rules_table.create!(
          id: existing_push_rule.id,
          project_id: another_project.id,
          created_at: existing_push_rule.created_at,
          updated_at: existing_push_rule.updated_at,
          **push_rule_attributes.merge(commit_message_regex: 'Another message')
        )
      end

      it 'only migrates the missing push rule' do
        expect { perform_migration }.to change { project_push_rules_table.count }.by(1)

        expect(project_push_rules_table.find_by(id: missing_push_rule.id)).to be_present
      end
    end
  end
end
