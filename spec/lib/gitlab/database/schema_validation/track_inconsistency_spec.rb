# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::TrackInconsistency, feature_category: :database do
  describe '#execute' do
    let(:validator) { Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionIndexes }

    let(:database_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (namespace_id)' }
    let(:structure_sql_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (id)' }

    let(:structure_stmt) { PgQuery.parse(structure_sql_statement).tree.stmts.first.stmt.index_stmt }
    let(:database_stmt) { PgQuery.parse(database_statement).tree.stmts.first.stmt.index_stmt }

    let(:structure_sql_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Index.new(structure_stmt) }
    let(:database_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Index.new(database_stmt) }

    let(:inconsistency) do
      Gitlab::Database::SchemaValidation::Inconsistency.new(validator, structure_sql_object, database_object)
    end

    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    subject(:execute) { described_class.new(inconsistency, project, user).execute }

    context 'when is not GitLab.com' do
      it 'does not create a schema inconsistency record' do
        allow(Gitlab).to receive(:com?).and_return(false)

        expect { execute }.not_to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
      end
    end

    context 'when the issue creation fails' do
      let(:issue_creation) { instance_double(Mutations::Issues::Create, resolve: { errors: 'error' }) }

      let(:convert_object) do
        instance_double('Gitlab::Database::ConvertFeatureCategoryToGroupLabel', execute: 'group_label')
      end

      before do
        allow(Gitlab::Database::ConvertFeatureCategoryToGroupLabel).to receive(:new).and_return(convert_object)
        allow(Mutations::Issues::Create).to receive(:new).and_return(issue_creation)
      end

      it 'does not create a schema inconsistency record' do
        allow(Gitlab).to receive(:com?).and_return(true)

        expect { execute }.not_to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
      end
    end

    context 'when a new inconsistency is found' do
      let(:convert_object) do
        instance_double('Gitlab::Database::ConvertFeatureCategoryToGroupLabel', execute: 'group_label')
      end

      before do
        allow(Gitlab::Database::ConvertFeatureCategoryToGroupLabel).to receive(:new).and_return(convert_object)
        project.add_developer(user)
      end

      it 'creates a new schema inconsistency record' do
        allow(Gitlab).to receive(:com?).and_return(true)

        expect { execute }.to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
      end
    end

    context 'when the schema inconsistency already exists' do
      let(:diff) do
        "-#{structure_sql_statement}\n" \
          "+#{database_statement}\n"
      end

      let!(:schema_inconsistency) do
        create(:schema_inconsistency, object_name: 'index_name', table_name: 'achievements',
          valitador_name: 'different_definition_indexes', diff: diff)
      end

      before do
        project.add_developer(user)
      end

      context 'when the issue has the last schema inconsistency' do
        it 'does not add a note' do
          allow(Gitlab).to receive(:com?).and_return(true)

          expect { execute }.not_to change { schema_inconsistency.issue.notes.count }
        end
      end

      context 'when the issue is outdated' do
        let!(:schema_inconsistency) do
          create(:schema_inconsistency, object_name: 'index_name', table_name: 'achievements',
            valitador_name: 'different_definition_indexes', diff: 'old_diff')
        end

        it 'adds a note' do
          allow(Gitlab).to receive(:com?).and_return(true)

          expect { execute }.to change { schema_inconsistency.issue.notes.count }.from(0).to(1)
        end

        it 'updates the diff' do
          allow(Gitlab).to receive(:com?).and_return(true)

          execute

          expect(schema_inconsistency.reload.diff).to eq(diff)
        end
      end

      context 'when the GitLab issue is open' do
        it 'does not create a new schema inconsistency record' do
          allow(Gitlab).to receive(:com?).and_return(true)
          schema_inconsistency.issue.update!(state_id: Issue.available_states[:opened])

          expect { execute }.not_to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
        end
      end

      context 'when the GitLab is not open' do
        let(:convert_object) do
          instance_double('Gitlab::Database::ConvertFeatureCategoryToGroupLabel', execute: 'group_label')
        end

        before do
          allow(Gitlab::Database::ConvertFeatureCategoryToGroupLabel).to receive(:new).and_return(convert_object)
          project.add_developer(user)
        end

        it 'creates a new schema inconsistency record' do
          allow(Gitlab).to receive(:com?).and_return(true)
          schema_inconsistency.issue.update!(state_id: Issue.available_states[:closed])

          expect { execute }.to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
        end
      end
    end

    context 'when the dictionary file is not present' do
      before do
        allow(Gitlab::Database::GitlabSchema).to receive(:dictionary_paths).and_return(['dictionary_not_found_path/'])

        project.add_developer(user)
      end

      it 'add the default labels' do
        allow(Gitlab).to receive(:com?).and_return(true)

        inconsistency = execute

        labels = inconsistency.issue.labels.map(&:name)

        expect(labels).to eq %w[database database-inconsistency-report type::maintenance severity::4]
      end
    end

    context 'when dictionary feature_categories are available' do
      let(:convert_object) do
        instance_double('Gitlab::Database::ConvertFeatureCategoryToGroupLabel', execute: 'group_label')
      end

      before do
        allow(Gitlab::Database::ConvertFeatureCategoryToGroupLabel).to receive(:new).and_return(convert_object)

        allow(Gitlab::Database::GitlabSchema).to receive(:dictionary_paths).and_return(['spec/fixtures/'])

        project.add_developer(user)
      end

      it 'add the default labels + group labels' do
        allow(Gitlab).to receive(:com?).and_return(true)

        inconsistency = execute

        labels = inconsistency.issue.labels.map(&:name)

        expect(labels).to eq %w[database database-inconsistency-report type::maintenance severity::4 group_label]
      end
    end
  end
end
