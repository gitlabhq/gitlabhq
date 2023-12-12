# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FinishBatchedPipelineWorker, feature_category: :importers do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import
    )
  end

  let(:pipeline_class) do
    Class.new do
      def initialize(_); end

      def on_finish; end
    end
  end

  let(:pipeline_tracker) do
    create(
      :bulk_import_tracker,
      :started,
      :batched,
      entity: entity,
      pipeline_name: 'FakePipeline'
    )
  end

  let!(:batch_1) { create(:bulk_import_batch_tracker, :finished, tracker: pipeline_tracker) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    before do
      stub_const('FakePipeline', pipeline_class)

      allow_next_instance_of(BulkImports::Projects::Stage) do |instance|
        allow(instance).to receive(:pipelines)
          .and_return([{ stage: 0, pipeline: pipeline_class }])
      end
    end

    it 'marks the tracker as finished' do
      expect_next_instance_of(BulkImports::Logger) do |logger|
        expect(logger).to receive(:with_tracker).with(pipeline_tracker).and_call_original
        expect(logger).to receive(:with_entity).with(entity).and_call_original

        expect(logger).to receive(:info).with(
          a_hash_including('message' => 'Tracker finished')
        )
      end

      expect { subject.perform(pipeline_tracker.id) }
        .to change { pipeline_tracker.reload.finished? }
        .from(false).to(true)
    end

    it "calls the pipeline's `#on_finish`" do
      expect_next_instance_of(pipeline_class) do |pipeline|
        expect(pipeline).to receive(:on_finish)
      end

      subject.perform(pipeline_tracker.id)
    end

    context 'when import is in progress' do
      it 're-enqueues for any started batches' do
        create(:bulk_import_batch_tracker, :started, tracker: pipeline_tracker)

        expect(described_class)
          .to receive(:perform_in)
          .with(described_class::REQUEUE_DELAY, pipeline_tracker.id)

        subject.perform(pipeline_tracker.id)
      end

      it 're-enqueues for any created batches' do
        create(:bulk_import_batch_tracker, :created, tracker: pipeline_tracker)

        expect(described_class)
          .to receive(:perform_in)
          .with(described_class::REQUEUE_DELAY, pipeline_tracker.id)

        subject.perform(pipeline_tracker.id)
      end
    end

    context 'when pipeline tracker is stale' do
      before do
        batch_1.update!(updated_at: 5.hours.ago)
      end

      it 'fails pipeline tracker and its batches' do
        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:with_tracker).with(pipeline_tracker).and_call_original
          expect(logger).to receive(:with_entity).with(entity).and_call_original

          expect(logger).to receive(:error).with(
            a_hash_including('message' => 'Batch stale. Failing batches and tracker')
          )
        end

        subject.perform(pipeline_tracker.id)

        expect(pipeline_tracker.reload.failed?).to eq(true)
        expect(pipeline_tracker.batches.first.reload.failed?).to eq(true)
      end
    end
  end

  shared_examples 'does nothing' do
    it "does not call the tracker's `#finish!`" do
      expect_next_found_instance_of(BulkImports::Tracker) do |instance|
        expect(instance).not_to receive(:finish!)
      end

      subject.perform(pipeline_tracker.id)
    end

    it "does not call the pipeline's `#on_finish`" do
      expect(pipeline_class).not_to receive(:new)

      subject.perform(pipeline_tracker.id)
    end
  end

  context 'when tracker is not batched' do
    let(:pipeline_tracker) { create(:bulk_import_tracker, :started, entity: entity, batched: false) }

    include_examples 'does nothing'
  end

  context 'when tracker is not started' do
    let(:pipeline_tracker) { create(:bulk_import_tracker, :batched, :finished, entity: entity) }

    include_examples 'does nothing'
  end

  context 'when pipeline is enqueued' do
    let(:pipeline_tracker) { create(:bulk_import_tracker, status: 3, entity: entity) }

    include_examples 'does nothing'
  end
end
