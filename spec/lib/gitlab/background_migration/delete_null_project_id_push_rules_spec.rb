# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteNullProjectIdPushRules, feature_category: :source_code_management do
  let(:push_rules) { table(:push_rules) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'test-org', path: 'test-org') }
  let!(:namespace) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let!(:project_namespace) do
    namespaces.create!(name: 'test-project-ns', path: 'test-project-ns', type: 'Project',
      organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      name: 'test-project',
      path: 'test-project',
      organization_id: organization.id
    )
  end

  let!(:push_rule_with_project) do
    push_rules.create!(project_id: project.id, created_at: Time.current, updated_at: Time.current)
  end

  let!(:push_rule_null_project) do
    push_rules.create!(project_id: nil, created_at: Time.current, updated_at: Time.current)
  end

  let!(:push_rule_null_project_sample) do
    push_rules.create!(project_id: nil, is_sample: true, created_at: Time.current, updated_at: Time.current)
  end

  describe '#perform' do
    subject(:perform_migration) { described_class.new(**migration_args).perform }

    it 'deletes rows where project_id IS NULL', :aggregate_failures do
      expect { perform_migration }.to change { push_rules.count }.from(3).to(1)

      expect(push_rules.exists?(push_rule_with_project.id)).to be true
      expect(push_rules.exists?(push_rule_null_project.id)).to be false
      expect(push_rules.exists?(push_rule_null_project_sample.id)).to be false
    end

    it 'is idempotent', :aggregate_failures do
      2.times { perform_migration }

      expect(push_rules.where(project_id: nil).count).to eq(0)
      expect(push_rules.count).to eq(1)
    end

    context 'when there are no rows with NULL project_id' do
      before do
        push_rules.where(project_id: nil).delete_all
      end

      it 'does not delete anything' do
        expect { perform_migration }.not_to change { push_rules.count }
      end
    end
  end

  private

  def migration_args
    min, max = push_rules.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min || 0,
      end_id: max || 0,
      batch_table: 'push_rules',
      batch_column: 'id',
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end
end
