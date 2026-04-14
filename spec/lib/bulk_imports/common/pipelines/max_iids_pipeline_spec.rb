# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::MaxIidsPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let(:tmpdir) { Dir.mktmpdir }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }

  before_all do
    group.add_owner(user)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe 'pipeline attributes' do
    it 'is a file_extraction_pipeline' do
      expect(described_class.file_extraction_pipeline?).to be(true)
    end

    it 'has relation max_iids' do
      expect(described_class.relation).to eq('max_iids')
    end
  end

  describe '#transform' do
    let_it_be(:entity) do
      create(
        :bulk_import_entity,
        :project_entity,
        project: project,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'transform-project',
        destination_namespace: group.full_path
      )
    end

    let_it_be(:tracker) do
      create(:bulk_import_tracker, entity: entity, pipeline_name: described_class.to_s)
    end

    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    subject(:pipeline) { described_class.new(context) }

    it 'returns nil for non-Hash data' do
      expect(pipeline.transform(context, [1, 2, 3])).to be_nil
    end

    it 'returns nil for nil data' do
      expect(pipeline.transform(context, nil)).to be_nil
    end

    it 'returns nil for empty hash' do
      expect(pipeline.transform(context, {})).to be_nil
    end

    it 'filters out non-integer IID values' do
      data = { 'issues' => 42, 'merge_requests' => 'invalid', 'ci_pipelines' => 0 }

      result = pipeline.transform(context, data)

      expect(result).to eq({ issues: 42 })
    end

    it 'filters out negative IID values' do
      data = { 'issues' => -5, 'merge_requests' => 17 }

      result = pipeline.transform(context, data)

      expect(result).to eq({ merge_requests: 17 })
    end

    it 'filters out IID values exceeding MAX_VALID_IID' do
      data = { 'issues' => 42, 'merge_requests' => (2**31) }

      result = pipeline.transform(context, data)

      expect(result).to eq({ issues: 42 })
    end

    it 'filters out unknown keys' do
      data = { 'issues' => 42, 'unknown_resource' => 99, 'malicious_key' => 1 }

      result = pipeline.transform(context, data)

      expect(result).to eq({ issues: 42 })
    end

    it 'symbolizes keys and returns valid entries' do
      data = { 'issues' => 42, 'merge_requests' => 17 }

      result = pipeline.transform(context, data)

      expect(result).to eq({ issues: 42, merge_requests: 17 })
    end
  end

  context 'with a project entity' do
    let_it_be(:entity) do
      create(
        :bulk_import_entity,
        :project_entity,
        project: project,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'my-project',
        destination_namespace: group.full_path
      )
    end

    let_it_be(:tracker) do
      create(:bulk_import_tracker, entity: entity, pipeline_name: described_class.to_s)
    end

    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    subject(:pipeline) { described_class.new(context) }

    before do
      allow(pipeline).to receive(:set_source_objects_counter)
    end

    describe '#run' do
      let(:max_iids_data) { { 'issues' => 42, 'merge_requests' => 17 } }

      before do
        allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
        allow_next_instance_of(BulkImports::FileDownloadService) do |service|
          allow(service).to receive(:execute)
        end

        allow_next_instance_of(BulkImports::FileDecompressionService) do |service|
          allow(service).to receive(:execute)
        end

        write_max_iids_json(max_iids_data)
      end

      it 'calls IidPreallocator with the parsed data' do
        expect_next_instance_of(Gitlab::Import::IidPreallocator, project, { issues: 42, merge_requests: 17 }) do |p|
          expect(p).to receive(:execute)
        end

        pipeline.run
      end

      context 'when max_iids data is empty' do
        let(:max_iids_data) { {} }

        it 'does not call IidPreallocator' do
          expect(Gitlab::Import::IidPreallocator).not_to receive(:new)

          pipeline.run
        end
      end
    end
  end

  context 'with a group entity' do
    let_it_be(:entity) do
      create(
        :bulk_import_entity,
        group: group,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'My-Destination-Group',
        destination_namespace: group.full_path
      )
    end

    let_it_be(:tracker) do
      create(:bulk_import_tracker, entity: entity, pipeline_name: described_class.to_s)
    end

    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    subject(:pipeline) { described_class.new(context) }

    before do
      allow(pipeline).to receive(:set_source_objects_counter)
    end

    describe '#run' do
      let(:max_iids_data) { { 'group_milestones' => 8 } }

      before do
        allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
        allow_next_instance_of(BulkImports::FileDownloadService) do |service|
          allow(service).to receive(:execute)
        end

        allow_next_instance_of(BulkImports::FileDecompressionService) do |service|
          allow(service).to receive(:execute)
        end

        write_max_iids_json(max_iids_data)
      end

      it 'calls IidPreallocator with the parsed data' do
        expect_next_instance_of(Gitlab::Import::IidPreallocator, group, { group_milestones: 8 }) do |preallocator|
          expect(preallocator).to receive(:execute)
        end

        pipeline.run
      end
    end
  end

  def write_max_iids_json(data)
    # Write the raw JSON file (decompression service is mocked)
    File.write(File.join(tmpdir, 'max_iids.json'), data.to_json)
  end
end
