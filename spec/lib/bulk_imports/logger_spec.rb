# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Logger, feature_category: :importers do
  describe '#with_entity' do
    subject(:logger) { described_class.new('/dev/null').with_entity(entity) }

    let(:entity) { build(:bulk_import_entity) }

    it 'records the entity information' do
      output = logger.format_message('INFO', Time.zone.now, 'test', 'Hello world')
      data = Gitlab::Json.parse(output)

      expect(data).to include(
        'bulk_import_id' => entity.bulk_import_id,
        'bulk_import_entity_id' => entity.id,
        'bulk_import_entity_type' => entity.source_type,
        'source_full_path' => entity.source_full_path,
        'source_version' => entity.bulk_import.source_version_info.to_s
      )
    end
  end

  describe '#with_tracker' do
    subject(:logger) { described_class.new('/dev/null').with_tracker(tracker) }

    let_it_be(:tracker) { build(:bulk_import_tracker) }

    it 'records the tracker information' do
      output = logger.format_message('INFO', Time.zone.now, 'test', 'Hello world')
      data = Gitlab::Json.parse(output)

      expect(data).to include(
        'tracker_id' => tracker.id,
        'pipeline_class' => tracker.pipeline_name,
        'tracker_state' => tracker.human_status_name
      )
    end

    it 'also loads the entity data' do
      expect_next_instance_of(described_class) do |logger|
        expect(logger).to receive(:with_entity).once
      end

      logger
    end
  end
end
