# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Importers::GroupImporter do
  let(:user) { create(:user) }
  let(:bulk_import) { create(:bulk_import) }
  let(:bulk_import_entity) { create(:bulk_import_entity, bulk_import: bulk_import) }
  let(:bulk_import_configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let(:context) do
    instance_double(
      BulkImports::Pipeline::Context,
      current_user: user,
      entities: [bulk_import_entity],
      configuration: bulk_import_configuration
    )
  end

  subject { described_class.new(bulk_import_entity.id) }

  describe '#execute' do
    before do
      allow(BulkImports::Pipeline::Context).to receive(:new).and_return(context)
    end

    context 'when import entity does not have parent' do
      it 'executes GroupPipeline' do
        expect_next_instance_of(BulkImports::Groups::Pipelines::GroupPipeline) do |pipeline|
          expect(pipeline).to receive(:run).with(context)
        end

        subject.execute
      end
    end

    context 'when import entity has parent' do
      let(:bulk_import_entity_parent) { create(:bulk_import_entity, bulk_import: bulk_import) }
      let(:bulk_import_entity) { create(:bulk_import_entity, bulk_import: bulk_import, parent: bulk_import_entity_parent) }

      it 'does not execute GroupPipeline' do
        expect(BulkImports::Groups::Pipelines::GroupPipeline).not_to receive(:new)

        subject.execute
      end
    end
  end
end
