#  frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImportWorker do
  describe '#perform' do
    it 'executes Group Importer' do
      bulk_import_id = 1

      expect(BulkImports::Importers::GroupsImporter)
        .to receive(:new).with(bulk_import_id).and_return(double(execute: true))

      described_class.new.perform(bulk_import_id)
    end
  end
end
