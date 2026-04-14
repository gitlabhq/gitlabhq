# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::MaxIidsSaver, feature_category: :importers do
  let_it_be(:project) do
    create(:project).tap do |p|
      create(:issue, project: p, iid: 3)
      create(:issue, project: p, iid: 7)
      create(:merge_request, source_project: p, target_project: p, iid: 2, source_branch: 'feature-a')
      create(:merge_request, source_project: p, target_project: p, iid: 5, source_branch: 'feature-b')
      create(:milestone, project: p, iid: 4)
      create(:ci_pipeline, project: p, iid: 11)
      create(:design, project: p, iid: 6)
      create(:design, project: p, iid: 9)
    end
  end

  let(:shared) { project.import_export_shared }
  let(:export_path) { Dir.mktmpdir('max_iids_saver_spec') }

  before do
    allow(shared).to receive(:export_path).and_return(export_path)
  end

  after do
    FileUtils.rm_rf(export_path)
  end

  subject(:saver) { described_class.new(project: project, shared: shared) }

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

    it 'writes the correct max IID for each resource type' do
      expect(saver.save).to be true

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).to include(
        'issues' => 7,
        'merge_requests' => 5,
        'project_milestones' => 4,
        'ci_pipelines' => 11,
        'design_management_designs' => 9
      )
    end

    it 'omits resource types with no records' do
      empty_project = create(:project)
      allow(shared).to receive(:export_path).and_return(export_path)

      saver = described_class.new(project: empty_project, shared: shared)
      expect(saver.save).to be true

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).not_to have_key('issues')
      expect(content).not_to have_key('merge_requests')
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

      it 'adds the error to shared' do
        expect(saver.save).to be false

        expect(shared.errors).not_to be_empty
      end
    end
  end
end
