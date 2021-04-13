# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Tracker, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:entity).required }
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

  describe '.stage_running?' do
    it 'returns true if there is any unfinished pipeline in the given stage' do
      tracker = create(:bulk_import_tracker)

      expect(described_class.stage_running?(tracker.entity.id, 0))
        .to eq(true)
    end

    it 'returns false if there are no unfinished pipeline in the given stage' do
      tracker = create(:bulk_import_tracker, :finished)

      expect(described_class.stage_running?(tracker.entity.id, 0))
        .to eq(false)
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
      stage_2_tracker = create(:bulk_import_tracker, entity: entity, stage: 2)

      expect(described_class.next_pipeline_trackers_for(entity.id))
        .to include(stage_1_tracker)

      expect(described_class.next_pipeline_trackers_for(entity.id))
        .not_to include(stage_2_tracker)
    end
  end

  describe '#pipeline_class' do
    it 'returns the pipeline class' do
      pipeline_class = BulkImports::Stage.pipelines.first[1]
      tracker = create(:bulk_import_tracker, pipeline_name: pipeline_class)

      expect(tracker.pipeline_class).to eq(pipeline_class)
    end

    it 'raises an error when the pipeline is not valid' do
      tracker = create(:bulk_import_tracker, pipeline_name: 'InexistingPipeline')

      expect { tracker.pipeline_class }
        .to raise_error(
          NameError,
          "'InexistingPipeline' is not a valid BulkImport Pipeline"
        )
    end
  end
end
