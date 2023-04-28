# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationExportWorker, feature_category: :importers do
  let_it_be(:jid) { 'jid' }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:batched) { false }
  let(:relation) { 'labels' }
  let(:job_args) { [user.id, group.id, group.class.name, relation, batched] }

  describe '#perform' do
    include_examples 'an idempotent worker' do
      context 'when export record does not exist' do
        let(:another_group) { create(:group) }
        let(:job_args) { [user.id, another_group.id, another_group.class.name, relation, batched] }

        it 'creates export record' do
          another_group.add_owner(user)

          expect { perform_multiple(job_args) }
            .to change { another_group.bulk_import_exports.count }
            .from(0)
            .to(1)
        end
      end

      shared_examples 'export service' do |export_service|
        it 'executes export service' do
          group.add_owner(user)

          service = instance_double(export_service)

          expect(export_service)
            .to receive(:new)
            .with(user, group, relation, anything)
            .twice
            .and_return(service)
          expect(service).to receive(:execute).twice

          perform_multiple(job_args)
        end
      end

      context 'when export is batched' do
        let(:batched) { true }

        context 'when bulk_imports_batched_import_export feature flag is disabled' do
          before do
            stub_feature_flags(bulk_imports_batched_import_export: false)
          end

          include_examples 'export service', BulkImports::RelationExportService
        end

        context 'when bulk_imports_batched_import_export feature flag is enabled' do
          before do
            stub_feature_flags(bulk_imports_batched_import_export: true)
          end

          context 'when relation is batchable' do
            include_examples 'export service', BulkImports::BatchedRelationExportService
          end

          context 'when relation is not batchable' do
            let(:relation) { 'namespace_settings' }

            include_examples 'export service', BulkImports::RelationExportService
          end
        end
      end

      context 'when export is not batched' do
        include_examples 'export service', BulkImports::RelationExportService
      end
    end
  end
end
