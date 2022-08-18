# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationExportWorker, type: :worker do
  let(:project_relation_export) { create(:project_relation_export) }
  let(:job_args) { [project_relation_export.id] }

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    subject(:worker) { described_class.new }

    context 'when relation export has initial state queued' do
      let(:project_relation_export) { create(:project_relation_export) }

      it 'calls RelationExportService' do
        expect_next_instance_of(Projects::ImportExport::RelationExportService) do |service|
          expect(service).to receive(:execute)
        end

        worker.perform(project_relation_export.id)
      end
    end

    context 'when relation export does not have queued state' do
      let(:project_relation_export) { create(:project_relation_export, status_event: :start) }

      it 'does not call RelationExportService' do
        expect(Projects::ImportExport::RelationExportService).not_to receive(:new)

        worker.perform(project_relation_export.id)
      end
    end
  end
end
