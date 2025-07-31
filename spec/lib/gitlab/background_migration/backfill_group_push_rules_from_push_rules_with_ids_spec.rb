# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillGroupPushRulesFromPushRulesWithIds,
  feature_category: :source_code_management do
  let(:push_rules_table) { table(:push_rules) }
  let(:group_push_rules_table) { table(:group_push_rules) }
  let(:namespaces_table) { table(:namespaces) }
  let(:organizations_table) { table(:organizations) }

  let!(:organization) { organizations_table.create!(name: "Organization", path: "organization") }

  let!(:group_namespace) do
    namespaces_table.create!(
      name: 'group',
      path: 'group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:user_namespace) do
    namespaces_table.create!(
      name: 'user',
      path: 'user',
      type: 'User',
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

  let(:connection) { ActiveRecord::Base.connection }

  subject(:perform_migration) { described_class.new(**args).perform }

  around do |example|
    connection.transaction do
      connection.execute(<<~SQL)
        DROP TRIGGER IF EXISTS trigger_sync_namespace_to_group_push_rules ON namespaces;
      SQL

      example.run

      connection.execute(<<~SQL)
        CREATE TRIGGER trigger_sync_namespace_to_group_push_rules
        AFTER UPDATE ON namespaces
        FOR EACH ROW
        WHEN (OLD.push_rule_id IS DISTINCT FROM NEW.push_rule_id)
        EXECUTE FUNCTION sync_namespace_to_group_push_rules();
      SQL
    end
  end

  describe '#perform' do
    context 'when push rule is associated with a group' do
      let!(:push_rule) do
        push_rules_table.create!(**push_rule_attributes)
      end

      before do
        group_namespace.update!(push_rule_id: push_rule.id)
      end

      it 'creates a group_push_rules record with synced push_rule ID' do
        expect { perform_migration }.to change { group_push_rules_table.count }.by(1)

        group_push_rule = group_push_rules_table.last
        expect(group_push_rule.id).to eq(push_rule.id)
        expect(group_push_rule.group_id).to eq(group_namespace.id)
        expect(group_push_rule.commit_message_regex).to eq(push_rule.commit_message_regex)
        expect(group_push_rule.max_file_size).to eq(push_rule.max_file_size)
      end

      it 'copies all push rule attributes correctly', :freeze_time do
        perform_migration

        group_push_rule = group_push_rules_table.last
        expect(group_push_rule.deny_delete_tag).to eq(push_rule.deny_delete_tag)
        expect(group_push_rule.author_email_regex).to eq(push_rule.author_email_regex)
        expect(group_push_rule.member_check).to eq(push_rule.member_check)
        expect(group_push_rule.file_name_regex).to eq(push_rule.file_name_regex)
        expect(group_push_rule.prevent_secrets).to eq(push_rule.prevent_secrets)
        expect(group_push_rule.branch_name_regex).to eq(push_rule.branch_name_regex)
        expect(group_push_rule.reject_unsigned_commits).to eq(push_rule.reject_unsigned_commits)
        expect(group_push_rule.commit_committer_check).to eq(push_rule.commit_committer_check)
        expect(group_push_rule.commit_message_negative_regex).to eq(push_rule.commit_message_negative_regex)
        expect(group_push_rule.reject_non_dco_commits).to eq(push_rule.reject_non_dco_commits)
        expect(group_push_rule.commit_committer_name_check).to eq(push_rule.commit_committer_name_check)
        expect(group_push_rule.created_at).to eq(push_rule.created_at)
        expect(group_push_rule.updated_at).to eq(push_rule.updated_at)
      end
    end

    context 'when push rule is associated with a user namespace' do
      let!(:push_rule) do
        push_rules_table.create!(**push_rule_attributes)
      end

      before do
        user_namespace.update!(push_rule_id: push_rule.id)
      end

      it 'does not create a group_push_rules record' do
        expect { perform_migration }.not_to change { group_push_rules_table.count }
      end
    end

    context 'when push rule is not associated with any namespace' do
      let!(:push_rule) do
        push_rules_table.create!(**push_rule_attributes)
      end

      it 'does not create a group_push_rules record' do
        expect { perform_migration }.not_to change { group_push_rules_table.count }
      end
    end

    context 'when group_push_rules record already exists with different data' do
      let!(:push_rule) do
        push_rules_table.create!(**push_rule_attributes)
      end

      let!(:existing_group_push_rule) do
        group_push_rules_table.create!(
          id: push_rule.id,
          group_id: group_namespace.id,
          commit_message_regex: 'Old message',
          **push_rule_attributes.except(:commit_message_regex)
        )
      end

      before do
        group_namespace.update!(push_rule_id: push_rule.id)
      end

      it 'does not create a duplicate record' do
        expect { perform_migration }.not_to change { group_push_rules_table.count }
      end

      it 'updates the existing record with push_rule data' do
        perform_migration

        existing_group_push_rule.reload
        expect(existing_group_push_rule.commit_message_regex).not_to eq('Old message')
        expect(existing_group_push_rule.commit_message_regex).to eq(push_rule.commit_message_regex)
      end
    end

    context 'when group_push_rules record already exists with same data' do
      let!(:push_rule) do
        push_rules_table.create!(**push_rule_attributes)
      end

      let!(:existing_group_push_rule) do
        group_push_rules_table.create!(
          id: push_rule.id,
          group_id: group_namespace.id,
          **push_rule_attributes
        )
      end

      before do
        group_namespace.update!(push_rule_id: push_rule.id)
      end

      it 'does not create a duplicate record' do
        expect { perform_migration }.not_to change { group_push_rules_table.count }
      end

      it 'does not modify the existing record when data is identical' do
        perform_migration

        expect(existing_group_push_rule.reload.commit_message_regex).to eq(push_rule.commit_message_regex)
      end
    end

    context 'when multiple push rules are associated with different groups' do
      let!(:another_group_namespace) do
        namespaces_table.create!(
          name: 'another_group',
          path: 'another_group',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:push_rule1) do
        push_rules_table.create!(**push_rule_attributes)
      end

      let!(:push_rule2) do
        push_rules_table.create!(
          **push_rule_attributes.merge(commit_message_regex: 'Different message')
        )
      end

      before do
        group_namespace.update!(push_rule_id: push_rule1.id)
        another_group_namespace.update!(push_rule_id: push_rule2.id)
      end

      it 'creates group_push_rules records for both groups' do
        expect { perform_migration }.to change { group_push_rules_table.count }.by(2)

        group_push_rule1 = group_push_rules_table.find_by(id: push_rule1.id)
        group_push_rule2 = group_push_rules_table.find_by(id: push_rule2.id)

        expect(group_push_rule1.group_id).to eq(group_namespace.id)
        expect(group_push_rule1.commit_message_regex).to eq('Default commit message')

        expect(group_push_rule2.group_id).to eq(another_group_namespace.id)
        expect(group_push_rule2.commit_message_regex).to eq('Different message')
      end
    end
  end
end
