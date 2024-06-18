# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Tracker, type: :model, feature_category: :importers do
  describe 'associations' do
    it do
      is_expected.to belong_to(:entity).required.class_name('BulkImports::Entity')
        .with_foreign_key(:bulk_import_entity_id).inverse_of(:trackers)
    end
  end

  describe 'validations' do
    before do
      create(:bulk_import_tracker)
    end

    it { is_expected.to validate_presence_of(:relation) }
    it { is_expected.to validate_uniqueness_of(:relation).scoped_to(:bulk_import_entity_id) }

    it { is_expected.to validate_presence_of(:stage) }

    context 'when has_next_page is true' do
      it "validates presence of `next_page`" do
        tracker = build(:bulk_import_tracker, has_next_page: true)

        expect(tracker).not_to be_valid
        expect(tracker.errors).to include(:next_page)
      end
    end
  end

  describe '.running_trackers' do
    it 'returns trackers that are running for a given entity' do
      entity = create(:bulk_import_entity)
      BulkImports::Tracker.state_machines[:status].states.map(&:value).each do |status|
        create(:bulk_import_tracker, status: status, entity: entity)
      end

      expect(described_class.running_trackers(entity.id).pluck(:status)).to include(1, 3)
    end
  end

  describe '.next_pipeline_trackers_for' do
    let_it_be(:entity) { create(:bulk_import_entity) }
    let_it_be(:stage_0_tracker) { create(:bulk_import_tracker, :finished, entity: entity) }

    it 'returns empty when all the stages pipelines are finished' do
      expect(described_class.next_pipeline_trackers_for(entity.id))
        .to eq([])
    end

    it 'returns the not started pipeline trackers from the minimum stage number' do
      stage_1_tracker = create(:bulk_import_tracker, entity: entity, stage: 1)
      stage_1_finished_tracker = create(:bulk_import_tracker, :finished, entity: entity, stage: 1)
      stage_1_failed_tracker = create(:bulk_import_tracker, :failed, entity: entity, stage: 1)
      stage_1_skipped_tracker = create(:bulk_import_tracker, :skipped, entity: entity, stage: 1)
      stage_2_tracker = create(:bulk_import_tracker, entity: entity, stage: 2)

      expect(described_class.next_pipeline_trackers_for(entity.id))
        .to include(stage_1_tracker)

      expect(described_class.next_pipeline_trackers_for(entity.id))
        .not_to include(stage_2_tracker, stage_1_finished_tracker, stage_1_failed_tracker, stage_1_skipped_tracker)
    end
  end

  describe '#pipeline_class' do
    it 'returns the pipeline class' do
      entity = create(:bulk_import_entity)
      pipeline_class = BulkImports::Groups::Stage.new(entity).pipelines.first[:pipeline]
      tracker = create(:bulk_import_tracker, pipeline_name: pipeline_class)

      expect(tracker.pipeline_class).to eq(pipeline_class)
    end

    it 'raises an error when the pipeline is not valid' do
      tracker = create(:bulk_import_tracker, pipeline_name: 'InexistingPipeline')

      expect { tracker.pipeline_class }
        .to raise_error(
          BulkImports::Error,
          "'InexistingPipeline' is not a valid BulkImport Pipeline"
        )
    end

    context 'when using delegation methods' do
      context 'with group pipelines' do
        let(:entity) { create(:bulk_import_entity) }

        it 'does not raise' do
          entity.pipelines.each do |pipeline|
            tracker = create(:bulk_import_tracker, entity: entity, pipeline_name: pipeline[:pipeline])
            expect { tracker.abort_on_failure? }.not_to raise_error
            expect { tracker.file_extraction_pipeline? }.not_to raise_error
          end
        end
      end

      context 'with project pipelines' do
        let(:entity) { create(:bulk_import_entity, :project_entity) }

        it 'does not raise' do
          entity.pipelines.each do |pipeline|
            tracker = create(:bulk_import_tracker, entity: entity, pipeline_name: pipeline[:pipeline])
            expect { tracker.abort_on_failure? }.not_to raise_error
            expect { tracker.file_extraction_pipeline? }.not_to raise_error
          end
        end
      end
    end
  end

  describe '#checksums' do
    let(:tracker) { create(:bulk_import_tracker) }
    let(:checksums) { { source: 1, fetched: 1, imported: 1 } }

    before do
      allow(tracker).to receive(:file_extraction_pipeline?).and_return(true)
      allow(tracker).to receive_message_chain(:pipeline_class, :relation, :to_sym).and_return(:labels)
    end

    context 'when checksums are cached' do
      it 'returns the cached checksums' do
        allow(BulkImports::ObjectCounter).to receive(:summary).and_return(checksums)

        expect(tracker.checksums).to eq({ labels: checksums })
      end
    end

    context 'when checksums are persisted' do
      it 'returns the persisted checksums' do
        allow(BulkImports::ObjectCounter).to receive(:summary).and_return(nil)

        tracker.update!(
          source_objects_count: checksums[:source],
          fetched_objects_count: checksums[:fetched],
          imported_objects_count: checksums[:imported]
        )

        expect(tracker.checksums).to eq({ labels: checksums })
      end
    end

    context 'when pipeline is not a file extraction pipeline' do
      it 'returns nil' do
        allow(tracker).to receive(:file_extraction_pipeline?).and_return(false)

        expect(tracker.checksums).to be_nil
      end
    end
  end

  describe '#checksums_empty?' do
    let(:tracker) { create(:bulk_import_tracker) }

    before do
      allow(tracker).to receive_message_chain(:pipeline_class, :relation, :to_sym).and_return(:labels)
    end

    context 'when checksums are missing' do
      it 'returns true' do
        allow(tracker).to receive(:checksums).and_return(nil)

        expect(tracker.checksums_empty?).to eq(true)
      end
    end

    context 'when checksums are present' do
      it 'returns false' do
        allow(tracker)
          .to receive(:checksums)
          .and_return({ labels: { source: 1, fetched: 1, imported: 1 } })

        expect(tracker.checksums_empty?).to eq(false)
      end
    end

    context 'when checksums are all zeros' do
      it 'returns true' do
        allow(tracker)
          .to receive(:checksums)
          .and_return({ labels: { source: 0, fetched: 0, imported: 0 } })

        expect(tracker.checksums_empty?).to eq(true)
      end
    end
  end

  describe 'checksums persistence' do
    let(:tracker) { create(:bulk_import_tracker, :started) }

    context 'when transitioned to finished' do
      it 'persists the checksums' do
        expect(BulkImports::ObjectCounter).to receive(:persist!).with(tracker)

        tracker.finish!
      end
    end

    context 'when transitioned to failed' do
      it 'persists the checksums' do
        expect(BulkImports::ObjectCounter).to receive(:persist!).with(tracker)

        tracker.fail_op!
      end
    end
  end

  describe 'tracker canceling' do
    let(:tracker) { create(:bulk_import_tracker) }

    it 'marks tracker as canceled' do
      tracker.cancel!

      expect(tracker.canceled?).to eq(true)
    end

    context 'when tracker has batches' do
      it 'marks batches as canceled' do
        batch = create(:bulk_import_batch_tracker, tracker: tracker)

        tracker.cancel!

        expect(batch.reload.canceled?).to eq(true)
      end
    end
  end
end
