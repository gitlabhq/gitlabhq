# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::ExportStatus, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:offline_import) { create(:bulk_import, configuration: nil, offline_configuration: nil) }
  let_it_be(:entity) { create(:bulk_import_entity, :group_entity, :with_portable, bulk_import: offline_import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:configuration) do
    create(
      :import_offline_configuration,
      bulk_import: offline_import,
      entity_prefix_mapping: {
        entity.source_full_path => "group_#{entity.namespace_id}"
      }
    )
  end

  let(:relation) { 'labels' }
  let(:batch_keys) { [] }
  let(:export_and_entity_prefix) { "#{configuration.export_prefix}/group_#{entity.namespace_id}" }
  let(:batch_prefix) { "#{export_and_entity_prefix}/#{relation}" }
  let(:storage) { Fog::Storage.new(provider: 'AWS', **configuration.object_storage_credentials) }
  let(:directory) { storage.directories.new(key: configuration.bucket) }

  subject(:export_status) { described_class.new(tracker, relation) }

  before do
    stub_object_storage(
      connection_params: { provider: configuration.provider }.merge(configuration.object_storage_credentials),
      remote_directory: configuration.bucket
    )

    batch_keys.each do |key|
      directory.files.create(key: key, body: 'file content') # rubocop:disable Rails/SaveBang -- fog file collections do not use ActiveRecord
    end
  end

  describe '#in_progress?' do
    it 'always returns false' do
      expect(export_status.in_progress?).to be(false)
    end
  end

  describe '#waiting_on_export?' do
    it 'always returns false' do
      expect(export_status.waiting_on_export?).to be(false)
    end
  end

  describe '#batched?' do
    context 'when there are batched relation files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz"
        ]
      end

      it 'returns true' do
        expect(export_status.batched?).to be(true)
      end
    end

    context 'when there is one batched relation file' do
      let(:batch_keys) { ["#{batch_prefix}/batch_1.ndjson.gz"] }

      it 'returns true' do
        expect(export_status.batched?).to be(true)
      end
    end

    context 'when there is an unbatched file' do
      let(:batch_keys) { ["#{export_and_entity_prefix}/#{relation}.ndjson.gz"] }

      it 'returns false' do
        expect(export_status.batched?).to be(false)
      end
    end

    context 'when there are batched relation files and an unbatched relation file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{export_and_entity_prefix}/#{relation}.ndjson.gz"
        ]
      end

      it 'returns true' do
        expect(export_status.batched?).to be(true)
      end
    end

    context 'when there are batched relation files and an unknown file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{batch_prefix}/unknown_1.ndjson.gz"
        ]
      end

      it 'prioritizes batched files by returning true' do
        expect(export_status.batched?).to be(true)
      end
    end

    context 'when there is an unknown file and an unbatched relation files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{export_and_entity_prefix}/#{relation}.ndjson.gz"
        ]
      end

      it 'returns false' do
        expect(export_status.batched?).to be(false)
      end
    end

    context 'when there are multiple unknown files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{batch_prefix}/unknown_2.ndjson.gz"
        ]
      end

      it 'returns false' do
        expect(export_status.batched?).to be(false)
      end
    end

    context 'when there is one unknown file' do
      let(:batch_keys) { ["#{batch_prefix}/unknown_1.ndjson.gz"] }

      it 'returns false' do
        expect(export_status.batched?).to be(false)
      end
    end

    context 'when no files are found' do
      it 'returns false' do
        expect(export_status.batched?).to be(false)
      end
    end
  end

  describe '#batches_count' do
    context 'when there are batched relation files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{batch_prefix}/batch_3.ndjson.gz"
        ]
      end

      it 'returns the number of batch files' do
        expect(export_status.batches_count).to eq(3)
      end
    end

    context 'when missing some batched relation files' do
      let(:batch_keys) { ["#{batch_prefix}/batch_3.ndjson.gz"] }

      it 'returns the number of batch files found' do
        expect(export_status.batches_count).to eq(1)
      end
    end

    context 'when the relation is not batched' do
      let(:batch_keys) { ["#{export_and_entity_prefix}/#{relation}.ndjson.gz"] }

      it 'returns 0' do
        expect(export_status.batches_count).to eq(0)
      end
    end

    context 'when there are batched relation files and an unbatched relation file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{export_and_entity_prefix}/#{relation}.ndjson.gz"
        ]
      end

      it 'returns only the count of batch files' do
        expect(export_status.batches_count).to eq(2)
      end
    end

    context 'when there are batched relation files and an unknown file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{batch_prefix}/unknown_1.ndjson.gz"
        ]
      end

      it 'returns only the count of batch files' do
        expect(export_status.batches_count).to eq(2)
      end
    end

    context 'when there are batched relation files, missing batch files, and an unknown file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_3.ndjson.gz",
          "#{batch_prefix}/unknown_1.ndjson.gz"
        ]
      end

      it 'returns the number of batch files found' do
        expect(export_status.batches_count).to eq(2)
      end
    end

    context 'when there is an unknown file and an unbatched relation files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{export_and_entity_prefix}/#{relation}.ndjson.gz"
        ]
      end

      it 'returns 0' do
        expect(export_status.batches_count).to eq(0)
      end
    end

    context 'when there are unknown files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{batch_prefix}/unknown_2.ndjson.gz"
        ]
      end

      it 'returns 0' do
        expect(export_status.batches_count).to eq(0)
      end
    end

    context 'when no files are found' do
      it 'returns 0' do
        expect(export_status.batches_count).to eq(0)
      end
    end
  end

  describe '#all_batch_numbers' do
    context 'when batched' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_5.ndjson.gz",
          "#{batch_prefix}/batch_1000.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{batch_prefix}/unknown_100.ndjson.gz"
        ]
      end

      it 'returns a sorted array of batch numbers present in batched object keys' do
        expect(export_status.all_batch_numbers).to eq([1, 2, 5, 1000])
      end
    end

    context 'when not batched' do
      let(:batch_keys) { ["#{export_and_entity_prefix}/#{relation}.ndjson.gz"] }

      it 'returns an empty array' do
        expect(export_status.all_batch_numbers).to be_empty
      end
    end
  end

  describe '#batch_error' do
    let(:batch_keys) do
      [
        "#{batch_prefix}/batch_1.ndjson.gz",
        "#{batch_prefix}/batch_2.ndjson.gz",
        "#{batch_prefix}/unknown_3.ndjson.gz"
      ]
    end

    context 'when batch is not present' do
      it 'returns a missing batch file error' do
        expect(export_status.batch_error(3)).to eq(
          "Export relation batch file not found for relation: #{relation}, batch: 3"
        )
      end
    end

    context 'when batch is present' do
      it 'returns nil' do
        expect(export_status.batch_error(1)).to be_nil
      end
    end
  end

  describe '#failed?' do
    context 'when there are batched relation files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz"
        ]
      end

      it 'returns false' do
        expect(export_status.failed?).to be(false)
      end
    end

    context 'when there is one batched relation file' do
      let(:batch_keys) { ["#{batch_prefix}/batch_1.ndjson.gz"] }

      it 'returns false' do
        expect(export_status.failed?).to be(false)
      end
    end

    context 'when missing some batched relation files' do
      let(:batch_keys) { ["#{batch_prefix}/batch_3.ndjson.gz"] }

      it 'returns false' do
        expect(export_status.failed?).to be(false)
      end
    end

    context 'when there is an unbatched file' do
      let(:batch_keys) { ["#{export_and_entity_prefix}/#{relation}.ndjson.gz"] }

      it 'returns false' do
        expect(export_status.failed?).to be(false)
      end
    end

    context 'when there are batched relation files and an unbatched relation file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{export_and_entity_prefix}/#{relation}.ndjson.gz"
        ]
      end

      it 'returns false' do
        expect(export_status.failed?).to be(false)
      end
    end

    context 'when there are batched relation files and an unknown file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{batch_prefix}/unknown_1.ndjson.gz"
        ]
      end

      it 'returns false' do
        expect(export_status.failed?).to be(false)
      end
    end

    context 'when there is an unknown file and an unbatched relation files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{export_and_entity_prefix}/#{relation}.ndjson.gz"
        ]
      end

      it 'returns false' do
        expect(export_status.failed?).to be(false)
      end
    end

    context 'when there are no files matching batched or unbatched key patterns' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{batch_prefix}/unknown_2.ndjson.gz"
        ]
      end

      it 'returns true' do
        expect(export_status.failed?).to be(true)
      end
    end

    context 'when no files are found' do
      it 'returns true' do
        expect(export_status.failed?).to be(true)
      end
    end
  end

  describe '#error' do
    context 'when there are batched relation files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz"
        ]
      end

      it 'returns nil' do
        expect(export_status.error).to be_nil
      end
    end

    context 'when there is one batched relation file' do
      let(:batch_keys) { ["#{batch_prefix}/batch_1.ndjson.gz"] }

      it 'returns nil' do
        expect(export_status.error).to be_nil
      end
    end

    context 'when missing some batched relation files' do
      let(:batch_keys) { ["#{batch_prefix}/batch_3.ndjson.gz"] }

      it 'returns nil' do
        expect(export_status.error).to be_nil
      end
    end

    context 'when there is an unbatched file' do
      let(:batch_keys) { ["#{export_and_entity_prefix}/#{relation}.ndjson.gz"] }

      it 'returns nil' do
        expect(export_status.error).to be_nil
      end
    end

    context 'when there are batched relation files and an unbatched relation file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{export_and_entity_prefix}/#{relation}.ndjson.gz"
        ]
      end

      it 'returns nil' do
        expect(export_status.error).to be_nil
      end
    end

    context 'when there are batched relation files and an unknown file' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{batch_prefix}/unknown_1.ndjson.gz"
        ]
      end

      it 'returns nil' do
        expect(export_status.error).to be_nil
      end
    end

    context 'when there is an unknown file and an unbatched relation files' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{export_and_entity_prefix}/#{relation}.ndjson.gz"
        ]
      end

      it 'returns nil' do
        expect(export_status.error).to be_nil
      end
    end

    context 'when there are no files matching batched or unbatched key patterns' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/unknown_1.ndjson.gz",
          "#{batch_prefix}/unknown_2.ndjson.gz"
        ]
      end

      it 'returns missing relation error' do
        expect(export_status.error).to eq("Export files not found for relation: #{relation}")
      end
    end

    context 'when no files are found' do
      it 'returns true' do
        expect(export_status.error).to eq("Export files not found for relation: #{relation}")
      end
    end
  end

  describe '#batch_failed?' do
    context 'when batch_number is present in batched relation keys' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_2.ndjson.gz",
          "#{batch_prefix}/batch_3.ndjson.gz"
        ]
      end

      it 'returns false' do
        expect(export_status.batch_failed?(2)).to be(false)
      end
    end

    context 'when batch_number is not present in batched relation keys' do
      let(:batch_keys) do
        [
          "#{batch_prefix}/batch_1.ndjson.gz",
          "#{batch_prefix}/batch_3.ndjson.gz",
          "#{batch_prefix}/unknown_2.ndjson.gz",
          "#{export_and_entity_prefix}/milestones/batch_2.ndjson.gz"
        ]
      end

      it 'returns true' do
        expect(export_status.batch_failed?(2)).to be(true)
      end
    end

    context 'when batch_number is less than 1' do
      let(:batch_keys) { ["#{batch_prefix}/batch_1.ndjson.gz"] }

      it 'raises ArgumentError' do
        expect { export_status.batch_failed?(0) }.to raise_error(
          ArgumentError, 'Batch number (0) must be >= 1'
        )
      end
    end
  end

  describe '#total_objects_count' do
    it 'returns 0' do
      expect(export_status.total_objects_count).to eq(0)
    end
  end

  describe 'caching' do
    let(:batch_keys) do
      [
        "#{batch_prefix}/batch_1.ndjson.gz",
        "#{batch_prefix}/batch_2.ndjson.gz"
      ]
    end

    it 'caches the status after first access' do
      expect_next_instance_of(Import::Clients::ObjectStorage) do |client|
        expect(client).to receive(:object_keys_for_prefix).once.and_call_original
      end

      2.times { export_status.batched? }
    end
  end
end
