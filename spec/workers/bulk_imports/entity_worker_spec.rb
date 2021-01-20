# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::EntityWorker do
  describe '#execute' do
    let(:bulk_import) { create(:bulk_import) }

    context 'when started entity exists' do
      let(:entity) { create(:bulk_import_entity, :started, bulk_import: bulk_import) }

      it 'executes BulkImports::Importers::GroupImporter' do
        expect(BulkImports::Importers::GroupImporter).to receive(:new).with(entity).and_call_original

        subject.perform(entity.id)
      end

      it 'sets jid' do
        jid = 'jid'

        allow(subject).to receive(:jid).and_return(jid)

        subject.perform(entity.id)

        expect(entity.reload.jid).to eq(jid)
      end
    end

    context 'when started entity does not exist' do
      it 'does not execute BulkImports::Importers::GroupImporter' do
        entity = create(:bulk_import_entity, bulk_import: bulk_import)

        expect(BulkImports::Importers::GroupImporter).not_to receive(:new)

        subject.perform(entity.id)
      end
    end
  end
end
