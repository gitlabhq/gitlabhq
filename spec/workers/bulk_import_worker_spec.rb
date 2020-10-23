#  frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImportWorker do
  let!(:bulk_import) { create(:bulk_import, :started) }
  let!(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }
  let(:importer) { double(execute: nil) }

  subject { described_class.new }

  describe '#perform' do
    before do
      allow(BulkImports::Importers::GroupImporter).to receive(:new).and_return(importer)
    end

    it 'executes Group Importer' do
      expect(importer).to receive(:execute)

      subject.perform(bulk_import.id)
    end

    it 'updates bulk import and entity state' do
      subject.perform(bulk_import.id)

      expect(bulk_import.reload.human_status_name).to eq('finished')
      expect(entity.reload.human_status_name).to eq('finished')
    end

    context 'when bulk import could not be found' do
      it 'does nothing' do
        expect(bulk_import).not_to receive(:top_level_groups)
        expect(bulk_import).not_to receive(:finish!)

        subject.perform(non_existing_record_id)
      end
    end
  end
end
