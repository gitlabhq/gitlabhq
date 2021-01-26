# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Importers::GroupImporter do
  let(:user) { create(:user) }
  let(:bulk_import) { create(:bulk_import) }
  let(:bulk_import_entity) { create(:bulk_import_entity, :started, bulk_import: bulk_import) }
  let(:bulk_import_configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let(:context) do
    BulkImports::Pipeline::Context.new(
      current_user: user,
      entity: bulk_import_entity,
      configuration: bulk_import_configuration
    )
  end

  subject { described_class.new(bulk_import_entity) }

  before do
    allow(BulkImports::Pipeline::Context).to receive(:new).and_return(context)
  end

  describe '#execute' do
    it 'starts the entity and run its pipelines' do
      expect_to_run_pipeline BulkImports::Groups::Pipelines::GroupPipeline, context: context
      expect_to_run_pipeline BulkImports::Groups::Pipelines::LabelsPipeline, context: context
      expect_to_run_pipeline('EE::BulkImports::Groups::Pipelines::EpicsPipeline'.constantize, context: context) if Gitlab.ee?
      expect_to_run_pipeline BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline, context: context

      subject.execute

      expect(bulk_import_entity.reload).to be_finished
    end

    context 'when failed' do
      let(:bulk_import_entity) { create(:bulk_import_entity, :failed, bulk_import: bulk_import) }

      it 'does not transition entity to finished state' do
        allow(bulk_import_entity).to receive(:start!)

        subject.execute

        expect(bulk_import_entity.reload).to be_failed
      end
    end
  end

  def expect_to_run_pipeline(klass, context:)
    expect_next_instance_of(klass) do |pipeline|
      expect(pipeline).to receive(:run).with(context)
    end
  end
end
