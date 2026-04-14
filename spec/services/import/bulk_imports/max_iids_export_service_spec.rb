# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::MaxIidsExportService, feature_category: :importers do
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

  let(:export_path) { Dir.mktmpdir('max_iids_export_spec') }

  after do
    FileUtils.rm_rf(export_path)
  end

  subject(:service) { described_class.new(project, export_path) }

  describe '#execute' do
    it 'writes max_iids.json to the export path' do
      service.execute

      expect(File).to exist(File.join(export_path, 'max_iids.json'))
    end

    it 'writes the correct max IID for each resource type' do
      service.execute

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
      empty_service = described_class.new(empty_project, export_path)

      empty_service.execute

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).to eq({})
    end
  end

  describe '#exported_filename' do
    it 'returns the expected filename' do
      expect(service.exported_filename).to eq('max_iids.json')
    end
  end

  describe '#exported_objects_count' do
    it 'returns 1 for a single metadata file' do
      expect(service.exported_objects_count).to eq(1)
    end
  end

  describe 'resource_queries delegation' do
    it 'uses Project::MaxIidsSaver.resource_queries for projects' do
      project_service = described_class.new(project, export_path)

      expect(project_service.send(:resource_queries)).to eq(
        Gitlab::ImportExport::Project::MaxIidsSaver.resource_queries
      )
    end

    it 'uses Group::MaxIidsSaver.resource_queries for groups' do
      group = create(:group)
      group_service = described_class.new(group, export_path)

      expect(group_service.send(:resource_queries)).to eq(
        Gitlab::ImportExport::Group::MaxIidsSaver.resource_queries
      )
    end

    context 'with an unsupported portable type' do
      it 'logs a warning and returns an empty hash' do
        unsupported_portable = build(:user)
        unsupported_service = described_class.new(unsupported_portable, export_path)

        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: 'MaxIidsExportService: unsupported portable type',
          portable_type: 'User'
        )

        expect(unsupported_service.send(:resource_queries)).to eq({})
      end
    end
  end

  context 'with a group portable' do
    let_it_be(:group) do
      create(:group).tap do |g|
        create(:milestone, group: g, iid: 8)
      end
    end

    subject(:service) { described_class.new(group, export_path) }

    it 'writes the correct max IID for group resources' do
      service.execute

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).to include(
        'group_milestones' => 8
      )
    end

    it 'omits project-only resource types' do
      service.execute

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).not_to have_key('issues')
      expect(content).not_to have_key('merge_requests')
      expect(content).not_to have_key('ci_pipelines')
      expect(content).not_to have_key('design_management_designs')
    end
  end
end
