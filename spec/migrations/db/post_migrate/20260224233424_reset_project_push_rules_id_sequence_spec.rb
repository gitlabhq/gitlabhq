# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResetProjectPushRulesIdSequence, feature_category: :source_code_management do
  let(:push_rules_table) { table(:push_rules) }
  let(:project_push_rules_table) { table(:project_push_rules) }

  around do |example|
    Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
      Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
        example.run
      end
    end
  end

  describe '#up' do
    context 'when project_push_rules table is empty' do
      it 'advances the sequence to at least 100' do
        expect(project_push_rules_table.count).to eq(0)

        migrate!

        sequence_value = Gitlab::Database::PostgresSequence.find_by(seq_name: 'project_push_rules_id_seq').last_value

        expect(sequence_value).to be >= 100
      end
    end

    context 'when project_push_rules table has records' do
      let!(:organization) { table(:organizations).create!(name: 'Organization', path: 'organization') }
      let!(:namespace) do
        table(:namespaces).create!(
          name: 'Namespace', path: 'namespace', type: 'Group', organization_id: organization.id
        )
      end

      let!(:project_namespace) do
        table(:namespaces).create!(
          name: 'Project',
          path: 'project',
          type: 'Project',
          organization_id: organization.id,
          parent_id: namespace.id
        )
      end

      let!(:project) do
        table(:projects).create!(
          name: 'Project',
          path: 'project',
          namespace_id: namespace.id,
          project_namespace_id: project_namespace.id,
          organization_id: organization.id
        )
      end

      let!(:push_rule) do
        push_rules_table.create!(project_id: project.id, created_at: Time.current, updated_at: Time.current)
      end

      it 'advances the sequence to at least MAX(id) + 100' do
        migrate!

        max_id = project_push_rules_table.maximum(:id)
        sequence_value = Gitlab::Database::PostgresSequence.find_by(seq_name: 'project_push_rules_id_seq').last_value

        expect(max_id).to be_present
        expect(sequence_value).to be >= max_id + 100
      end
    end
  end
end
