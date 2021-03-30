# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Importers::GroupImporter do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, :started, group: group) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity, pipeline_name: described_class.name) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  before do
    allow(BulkImports::Pipeline::Context).to receive(:new).and_return(context)
  end

  subject { described_class.new(entity) }

  describe '#execute' do
    it 'starts the entity and run its pipelines' do
      expect_to_run_pipeline BulkImports::Groups::Pipelines::GroupPipeline, context: context
      expect_to_run_pipeline BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline, context: context
      expect_to_run_pipeline BulkImports::Groups::Pipelines::MembersPipeline, context: context
      expect_to_run_pipeline BulkImports::Groups::Pipelines::LabelsPipeline, context: context
      expect_to_run_pipeline BulkImports::Groups::Pipelines::MilestonesPipeline, context: context
      expect_to_run_pipeline BulkImports::Groups::Pipelines::BadgesPipeline, context: context

      if Gitlab.ee?
        expect_to_run_pipeline('EE::BulkImports::Groups::Pipelines::EpicsPipeline'.constantize, context: context)
        expect_to_run_pipeline('EE::BulkImports::Groups::Pipelines::EpicAwardEmojiPipeline'.constantize, context: context)
        expect_to_run_pipeline('EE::BulkImports::Groups::Pipelines::EpicEventsPipeline'.constantize, context: context)
        expect_to_run_pipeline('EE::BulkImports::Groups::Pipelines::IterationsPipeline'.constantize, context: context)
      end

      subject.execute

      expect(entity).to be_finished
    end

    context 'when failed' do
      let(:entity) { create(:bulk_import_entity, :failed, bulk_import: bulk_import, group: group) }

      it 'does not transition entity to finished state' do
        allow(entity).to receive(:start!)

        subject.execute

        expect(entity.reload).to be_failed
      end
    end
  end

  def expect_to_run_pipeline(klass, context:)
    expect_next_instance_of(klass, context) do |pipeline|
      expect(pipeline).to receive(:run)
    end
  end
end
