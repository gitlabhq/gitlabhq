# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::MaxIidsSaver, feature_category: :importers do
  let_it_be(:group) do
    create(:group).tap do |g|
      create(:milestone, group: g, iid: 2)
      create(:milestone, group: g, iid: 5)
    end
  end

  let(:shared) { instance_double(Gitlab::ImportExport::Shared, export_path: export_path, error: nil) }
  let(:export_path) { Dir.mktmpdir('group_max_iids_saver_spec') }

  after do
    FileUtils.rm_rf(export_path)
  end

  subject(:saver) { described_class.new(group: group, shared: shared) }

  describe '.resource_queries keys' do
    it 'are all recognized by IidPreallocator' do
      expect(described_class.resource_queries.keys).to all(
        be_in(Gitlab::Import::IidPreallocator.trackable_resources.keys)
      )
    end
  end

  describe '#save' do
    it 'returns true' do
      expect(saver.save).to be true
    end

    it 'writes max_iids.json to the export path' do
      expect(saver.save).to be true

      expect(File).to exist(File.join(export_path, 'max_iids.json'))
    end

    it 'writes the correct max IID for group_milestones' do
      expect(saver.save).to be true

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).to include('group_milestones' => 5)
    end

    it 'does not include project-scoped resources' do
      expect(saver.save).to be true

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content.keys).not_to include('issues', 'merge_requests', 'ci_pipelines')
    end

    it 'omits resource types with no records' do
      empty_group = create(:group)
      saver = described_class.new(group: empty_group, shared: shared)

      expect(saver.save).to be true

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).not_to have_key('group_milestones')
    end

    context 'when an error occurs' do
      before do
        allow_next_instance_of(Gitlab::ImportExport::Json::NdjsonWriter) do |writer|
          allow(writer).to receive(:write_attributes).and_raise(Errno::EACCES, 'Permission denied')
        end
      end

      it 'returns false' do
        expect(saver.save).to be false
      end

      it 'reports the error to shared' do
        expect(shared).to receive(:error).with(instance_of(Errno::EACCES))

        expect(saver.save).to be false
      end
    end
  end
end
