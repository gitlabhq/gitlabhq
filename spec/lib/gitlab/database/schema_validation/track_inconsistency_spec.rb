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

    before do
      stub_spam_services
    end

    context 'when is not GitLab.com' do
      it 'does not create a schema inconsistency record' do
        allow(Gitlab).to receive(:com?).and_return(false)

        expect { execute }.not_to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
      end
    end

    context 'when the issue creation fails' do
      let(:issue_creation) { instance_double(Mutations::Issues::Create, resolve: { errors: 'error' }) }

      before do
        allow(Mutations::Issues::Create).to receive(:new).and_return(issue_creation)
      end

      it 'does not create a schema inconsistency record' do
        allow(Gitlab).to receive(:com?).and_return(true)

        expect { execute }.not_to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
      end
    end

    context 'when a new inconsistency is found' do
      before do
        project.add_developer(user)
      end

      it 'creates a new schema inconsistency record' do
        allow(Gitlab).to receive(:com?).and_return(true)

        expect { execute }.to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
      end
    end

    context 'when the schema inconsistency already exists' do
      before do
        project.add_developer(user)
      end

      let!(:schema_inconsistency) do
        create(:schema_inconsistency, object_name: 'index_name', table_name: 'achievements',
          valitador_name: 'different_definition_indexes')
      end

      it 'does not create a schema inconsistency record' do
        allow(Gitlab).to receive(:com?).and_return(true)

        expect { execute }.not_to change { Gitlab::Database::SchemaValidation::SchemaInconsistency.count }
      end
    end
  end
end
