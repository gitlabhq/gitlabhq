# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::LooseForeignKeyCleanerService, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project) }
  let_it_be(:build) { create(:ci_build, project: project) }

  let(:schema) { Ci::ApplicationRecord.connection.current_schema }

  let(:loose_fk_definition) do
    ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
      'p_ci_job_artifacts',
      'projects',
      {
        column: 'project_id',
        on_delete: :async_delete,
        gitlab_schema: :gitlab_ci
      }
    )
  end

  let(:deleted_records) do
    [
      LooseForeignKeys::DeletedRecord.new(
        fully_qualified_table_name: "#{schema}.projects",
        primary_key_value: project.id
      )
    ]
  end

  let!(:artifact1) { create(:ci_job_artifact, :archive, job: build) }
  let!(:artifact2) { create(:ci_job_artifact, :metadata, job: build) }

  subject(:cleaner_service) do
    described_class.new(
      loose_foreign_key_definition: loose_fk_definition,
      connection: Ci::ApplicationRecord.connection,
      deleted_parent_records: deleted_records)
  end

  describe '#execute' do
    it 'captures the files in ci_deleted_objects before removing the artifact rows' do
      expect { cleaner_service.execute }
        .to change { Ci::JobArtifact.id_in([artifact1.id, artifact2.id]).count }.from(2).to(0)
        .and change { Ci::DeletedObject.count }.by(2)
    end

    it 'returns the number of affected rows and the table name' do
      expect(cleaner_service.execute).to eq(affected_rows: 2, table: 'p_ci_job_artifacts')
    end

    it 'reports the deletion as an async delete to the modification tracker' do
      expect(cleaner_service.async_delete?).to be(true)
    end

    it 'does not remove artifacts belonging to other projects' do
      other_artifact = create(:ci_job_artifact, :archive)

      cleaner_service.execute

      expect(Ci::JobArtifact.exists?(other_artifact.id)).to be(true)
    end

    context 'when a delete_limit is configured' do
      before do
        loose_fk_definition.options[:delete_limit] = 1
      end

      it 'only processes up to the limit per call' do
        expect { cleaner_service.execute }.to change { Ci::DeletedObject.count }.by(1)
      end
    end

    context 'when there are no matching artifacts' do
      let(:deleted_records) do
        [
          LooseForeignKeys::DeletedRecord.new(
            fully_qualified_table_name: "#{schema}.projects",
            primary_key_value: non_existing_record_id
          )
        ]
      end

      it 'does nothing and reports zero affected rows', :aggregate_failures do
        expect { cleaner_service.execute }.not_to change { Ci::DeletedObject.count }
        expect(cleaner_service.execute).to eq(affected_rows: 0, table: 'p_ci_job_artifacts')
      end
    end

    context 'with skip locked' do
      subject(:cleaner_service) do
        described_class.new(
          loose_foreign_key_definition: loose_fk_definition,
          connection: Ci::ApplicationRecord.connection,
          deleted_parent_records: deleted_records,
          with_skip_locked: true)
      end

      it 'still captures and removes the artifacts' do
        expect { cleaner_service.execute }
          .to change { Ci::JobArtifact.id_in([artifact1.id, artifact2.id]).count }.from(2).to(0)
          .and change { Ci::DeletedObject.count }.by(2)
      end
    end
  end
end
