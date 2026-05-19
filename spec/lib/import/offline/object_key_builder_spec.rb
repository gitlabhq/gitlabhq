# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::ObjectKeyBuilder, feature_category: :importers do
  let(:configuration) { build(:import_offline_configuration) }

  subject(:builder) { described_class.new(configuration) }

  describe '#metadata_object_key' do
    it 'returns the metadata object key' do
      expect(builder.metadata_object_key).to eq("#{configuration.export_prefix}/metadata.json.gz")
    end
  end

  describe '#upload_object_key' do
    let(:portable) { build_stubbed(:project) }

    context 'when batch_number is not present' do
      it 'returns a non-batched object key' do
        upload_object_key = builder.upload_object_key(
          portable: portable, relation: 'issues', extension: '.ndjson.gz'
        )

        expect(upload_object_key).to eq(
          "#{configuration.export_prefix}/project_#{portable.id}/issues.ndjson.gz"
        )
      end
    end

    context 'when batch_number is present' do
      it 'returns a batched object key' do
        upload_object_key = builder.upload_object_key(
          portable: portable, relation: 'issues', extension: '.ndjson.gz', batch_number: 1
        )

        expect(upload_object_key).to eq(
          "#{configuration.export_prefix}/project_#{portable.id}/issues/batch_1.ndjson.gz"
        )
      end
    end

    context 'when portable is a group' do
      let(:portable) { build_stubbed(:group) }

      it 'returns a key with the group entity prefix' do
        upload_object_key = builder.upload_object_key(
          portable: portable, relation: 'labels', extension: '.ndjson.gz'
        )

        expect(upload_object_key).to eq(
          "#{configuration.export_prefix}/group_#{portable.id}/labels.ndjson.gz"
        )
      end
    end
  end

  describe '#download_object_key' do
    let(:entity_source_full_path) { 'group/subgroup/project' }
    let(:entity_prefix) { 'group_123' }
    let(:batch_number) { nil }

    before do
      configuration.entity_prefix_mapping = { entity_source_full_path => entity_prefix }
    end

    context 'when batch_number is not present' do
      it 'returns a non-batched object key' do
        download_object_key = builder.download_object_key(
          relation: 'issues', entity_source_full_path: entity_source_full_path, extension: '.ndjson.gz'
        )

        expect(download_object_key).to eq("#{configuration.export_prefix}/#{entity_prefix}/issues.ndjson.gz")
      end
    end

    context 'when batch number is present' do
      it 'returns a batched object key' do
        download_object_key = builder.download_object_key(
          relation: 'issues', entity_source_full_path: entity_source_full_path, extension: '.ndjson.gz', batch_number: 1
        )

        expect(download_object_key).to eq("#{configuration.export_prefix}/#{entity_prefix}/issues/batch_1.ndjson.gz")
      end
    end

    context 'when no entity prefix exists for the full path' do
      it 'raises an error' do
        expect do
          builder.download_object_key(relation: 'issues', entity_source_full_path: 'not_found', extension: '.ndjson.gz')
        end.to raise_error(described_class::ObjectKeyError)
      end
    end
  end

  describe '#batched_object_key_prefix' do
    let(:entity_prefix) { 'group_1' }
    let(:relation) { 'issues' }

    it 'returns the prefix for batched object keys' do
      result = builder.batched_object_key_prefix(relation: relation, entity_prefix: entity_prefix)

      expect(result).to eq("#{configuration.export_prefix}/#{entity_prefix}/#{relation}")
    end
  end

  describe '#unbatched_relation_key?' do
    let(:export_prefix) { configuration.export_prefix }

    context 'when the object key matches the relation' do
      it 'returns true' do
        object_key = "#{export_prefix}/group_1/labels.ndjson.gz"

        expect(builder.unbatched_relation_key?(object_key, 'labels')).to be(true)
      end
    end

    context 'when the object key does not match the relation' do
      it 'returns false' do
        object_key = "#{export_prefix}/group_1/milestones.ndjson.gz"

        expect(builder.unbatched_relation_key?(object_key, 'labels')).to be(false)
      end
    end

    context 'when the object key is a batch file' do
      it 'returns false' do
        object_key = "#{export_prefix}/group_1/labels/batch_1.ndjson.gz"

        expect(builder.unbatched_relation_key?(object_key, 'labels')).to be(false)
      end
    end
  end

  describe '#batch_number' do
    let(:export_prefix) { configuration.export_prefix }

    context 'when the object key is a batch file' do
      it 'returns the batch number' do
        object_key = "#{export_prefix}/group_1/issues/batch_1.ndjson.gz"

        expect(builder.batch_number(object_key)).to eq(1)
      end

      it 'returns the correct number for multi-digit batch numbers' do
        object_key = "#{export_prefix}/group_1/issues/batch_42.ndjson.gz"

        expect(builder.batch_number(object_key)).to eq(42)
      end
    end

    context 'when the object key is not a batch file' do
      it 'returns nil' do
        object_key = "#{export_prefix}/group_1/issues.ndjson.gz"

        expect(builder.batch_number(object_key)).to be_nil
      end
    end

    context 'when the filename does not match batch pattern' do
      it 'returns nil for files without batch_ prefix' do
        object_key = "#{export_prefix}/group_1/issues/not_a_batch.ndjson.gz"

        expect(builder.batch_number(object_key)).to be_nil
      end
    end
  end
end
