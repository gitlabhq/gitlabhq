# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::SourceUsersAttributesWorker, feature_category: :importers do
  let_it_be_with_reload(:bulk_import) { create(:bulk_import, :with_configuration) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:bulk_import_entity_1) do
    create(:bulk_import_entity, :project_entity, project: project, bulk_import: bulk_import)
  end

  let_it_be(:bulk_import_entity_2) do
    create(:bulk_import_entity, :group_entity, group: group, bulk_import: bulk_import)
  end

  describe '#perform' do
    subject(:perform) { described_class.new.perform(bulk_import.id) }

    before do
      allow(described_class).to receive(:perform_in)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { bulk_import.id }

      before do
        allow_next_instance_of(BulkImports::Clients::Graphql) do |client|
          allow(client).to receive(:parse).and_return('query')
        end
      end
    end

    it 'executes UpdateSourceUsersService' do
      service_double = instance_double(Import::BulkImports::UpdateSourceUsersService)
      allow(service_double).to receive(:execute)

      expect(Import::BulkImports::UpdateSourceUsersService).to receive(:new).with(
        namespace: project.root_ancestor,
        bulk_import: bulk_import
      ).and_return(service_double).ordered

      expect(Import::BulkImports::UpdateSourceUsersService).to receive(:new).with(
        namespace: group,
        bulk_import: bulk_import
      ).and_return(service_double).ordered

      perform
    end

    it 're-enqueues the job' do
      allow_next_instance_of(Import::BulkImports::UpdateSourceUsersService) do |service|
        allow(service).to receive(:execute)
      end

      expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, bulk_import.id)

      perform
    end

    context 'when bulk_import is in a completed status' do
      before do
        allow(BulkImport).to receive(:find_by_id).and_return(bulk_import)
        allow(bulk_import).to receive(:completed?).and_return(true)
      end

      it 'executes UpdateSourceUsersService' do
        service_double = instance_double(Import::BulkImports::UpdateSourceUsersService)
        allow(service_double).to receive(:execute)

        expect(Import::BulkImports::UpdateSourceUsersService).to receive(:new).with(
          namespace: anything,
          bulk_import: bulk_import
        ).twice.and_return(service_double)

        perform
      end

      it 'does not re-enqueue the job' do
        allow_next_instance_of(Import::BulkImports::UpdateSourceUsersService) do |service|
          allow(service).to receive(:execute)
        end

        expect(described_class).not_to receive(:perform_in)

        perform
      end
    end
  end
end
