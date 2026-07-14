# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LooseForeignKeys::DeletedRecordStore, feature_category: :database do
  using RSpec::Parameterized::TableSyntax

  describe 'MODELS' do
    it 'contains the cell-local DeletedRecord and the four sharding-keyed models in that order' do
      expect(described_class::MODELS).to eq([
        LooseForeignKeys::DeletedRecord,
        LooseForeignKeys::OrganizationDeletedRecord,
        LooseForeignKeys::NamespaceDeletedRecord,
        LooseForeignKeys::ProjectDeletedRecord,
        LooseForeignKeys::UserDeletedRecord
      ])
    end

    it 'is frozen' do
      expect(described_class::MODELS).to be_frozen
    end
  end

  describe '.connection' do
    it 'returns the cell-local DeletedRecord connection' do
      expect(described_class.connection).to eq(LooseForeignKeys::DeletedRecord.connection)
    end
  end

  context 'with persisted records across every record store model' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    let_it_be(:cell_local_table) { 'public.projects' }
    let_it_be(:organization_table) { 'public.topics' }
    let_it_be(:namespace_table) { 'public.namespace_settings' }
    let_it_be(:project_table) { 'public.issues' }
    let_it_be(:user_table) { 'public.user_preferences' }

    let_it_be(:cell_local_record) do
      Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
        LooseForeignKeys::DeletedRecord.create!(fully_qualified_table_name: cell_local_table, primary_key_value: 11)
      end
    end

    let_it_be(:organization_record) do
      Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
        LooseForeignKeys::OrganizationDeletedRecord.create!(
          fully_qualified_table_name: organization_table,
          primary_key_value: 22,
          organization_id: organization.id
        )
      end
    end

    let_it_be(:namespace_record) do
      Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
        LooseForeignKeys::NamespaceDeletedRecord.create!(
          fully_qualified_table_name: namespace_table,
          primary_key_value: 33,
          namespace_id: namespace.id
        )
      end
    end

    let_it_be(:project_record) do
      Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
        LooseForeignKeys::ProjectDeletedRecord.create!(
          fully_qualified_table_name: project_table,
          primary_key_value: 44,
          project_id: project.id
        )
      end
    end

    let_it_be(:user_record) do
      Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
        LooseForeignKeys::UserDeletedRecord.create!(
          fully_qualified_table_name: user_table,
          primary_key_value: 55,
          user_id: user.id
        )
      end
    end

    describe '.load_batch_for_table' do
      where(:model, :table, :seeded_record) do
        [
          [LooseForeignKeys::DeletedRecord, ref(:cell_local_table), ref(:cell_local_record)],
          [LooseForeignKeys::OrganizationDeletedRecord, ref(:organization_table), ref(:organization_record)],
          [LooseForeignKeys::NamespaceDeletedRecord, ref(:namespace_table), ref(:namespace_record)],
          [LooseForeignKeys::ProjectDeletedRecord, ref(:project_table), ref(:project_record)],
          [LooseForeignKeys::UserDeletedRecord, ref(:user_table), ref(:user_record)]
        ]
      end

      with_them do
        it 'returns the record from the matching model', :aggregate_failures do
          Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
            result = described_class.load_batch_for_table(table, 10)

            expect(result.size).to eq(1)
            expect(result.first).to be_a(model)
            expect(result.first.id).to eq(seeded_record.id)
          end
        end
      end

      it 'returns an empty array when no records match the requested table' do
        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          expect(described_class.load_batch_for_table('public.no_such_table', 10)).to eq([])
        end
      end

      it 'delegates model processed counts to each metric type', :aggregate_failures do
        metrics = Gitlab::Metrics::LooseForeignKeysDeletedRecordStore

        expect(metrics).to receive(:record_loaded).with('loose_foreign_keys_deleted_records', cell_local_table, 1)

        described_class::MODELS.drop(1).each do |model|
          expect(metrics).to receive(:record_loaded).with(model.table_name, cell_local_table, 0)
        end

        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          described_class.load_batch_for_table(cell_local_table, 10)
        end
      end
    end

    describe '.mark_records_processed' do
      it 'marks records as processed across every model and returns the summed update count', :aggregate_failures do
        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          records = [
            *load_for(LooseForeignKeys::DeletedRecord, cell_local_table),
            *load_for(LooseForeignKeys::OrganizationDeletedRecord, organization_table),
            *load_for(LooseForeignKeys::NamespaceDeletedRecord, namespace_table),
            *load_for(LooseForeignKeys::ProjectDeletedRecord, project_table),
            *load_for(LooseForeignKeys::UserDeletedRecord, user_table)
          ]

          expect(described_class.mark_records_processed(records)).to eq(5)

          described_class::MODELS.each do |model|
            expect(model.status_processed.count).to be >= 1
          end
        end
      end

      it 'returns 0 when records is empty' do
        expect(described_class.mark_records_processed([])).to eq(0)
      end

      it 'delegates model processed counts to each metric type' do
        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          records = [
            *load_for(LooseForeignKeys::DeletedRecord, cell_local_table),
            *load_for(LooseForeignKeys::OrganizationDeletedRecord, organization_table)
          ]

          expect(Gitlab::Metrics::LooseForeignKeysDeletedRecordStore).to receive(:record_processed).with({
            'loose_foreign_keys_deleted_records' => 1,
            'loose_foreign_keys_organization_deleted_records' => 1
          })

          described_class.mark_records_processed(records)
        end
      end
    end

    describe '.reschedule' do
      it 'reschedules records across every model and resets cleanup_attempts', :aggregate_failures do
        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          consume_after = Time.zone.parse('2026-01-01 00:15:00')

          records = [
            *load_for(LooseForeignKeys::DeletedRecord, cell_local_table),
            *load_for(LooseForeignKeys::OrganizationDeletedRecord, organization_table),
            *load_for(LooseForeignKeys::NamespaceDeletedRecord, namespace_table),
            *load_for(LooseForeignKeys::ProjectDeletedRecord, project_table),
            *load_for(LooseForeignKeys::UserDeletedRecord, user_table)
          ]

          records.each { |record| record.class.where(id: record.id).update_all(cleanup_attempts: 4) }

          expect(described_class.reschedule(records, consume_after)).to eq(5)

          [cell_local_record, organization_record, namespace_record, project_record, user_record].each do |record|
            reloaded = record.reload
            expect(reloaded.cleanup_attempts).to eq(0)
            expect(reloaded.consume_after).to be_like_time(consume_after)
          end
        end
      end

      it 'returns 0 when records is empty' do
        expect(described_class.reschedule([], 1.minute.from_now)).to eq(0)
      end

      it 'delegates per-model load counts to the metrics collaborator' do
        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          records = load_for(LooseForeignKeys::DeletedRecord, cell_local_table)

          expect(Gitlab::Metrics::LooseForeignKeysDeletedRecordStore).to receive(:record_rescheduled)
            .with({ 'loose_foreign_keys_deleted_records' => 1 })

          described_class.reschedule(records, 1.minute.from_now)
        end
      end
    end

    describe '.increment_attempts' do
      it 'increments cleanup_attempts on records across every model', :aggregate_failures do
        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          records = [
            *load_for(LooseForeignKeys::DeletedRecord, cell_local_table),
            *load_for(LooseForeignKeys::OrganizationDeletedRecord, organization_table),
            *load_for(LooseForeignKeys::NamespaceDeletedRecord, namespace_table),
            *load_for(LooseForeignKeys::ProjectDeletedRecord, project_table),
            *load_for(LooseForeignKeys::UserDeletedRecord, user_table)
          ]

          expect(described_class.increment_attempts(records)).to eq(5)

          [cell_local_record, organization_record, namespace_record, project_record, user_record].each do |record|
            expect(record.reload.cleanup_attempts).to eq(1)
          end
        end
      end

      it 'returns 0 when records is empty' do
        expect(described_class.increment_attempts([])).to eq(0)
      end

      it 'delegates per-model load counts to the metrics collaborator' do
        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          records = load_for(LooseForeignKeys::DeletedRecord, cell_local_table)

          expect(Gitlab::Metrics::LooseForeignKeysDeletedRecordStore).to receive(:record_incremented)
            .with({ 'loose_foreign_keys_deleted_records' => 1 })

          described_class.increment_attempts(records)
        end
      end
    end

    def load_for(model, table)
      Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
        model.load_batch_for_table(table, 10)
      end
    end
  end
end
