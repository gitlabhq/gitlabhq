# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Projects::Pipelines::ProjectPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  describe '#run', :clean_gitlab_redis_shared_state do
    let_it_be(:group) { create(:group, :public) }
    let_it_be_with_reload(:bulk_import) { create(:bulk_import, user: user) }

    let_it_be_with_reload(:entity) do
      create(
        :bulk_import_entity,
        source_type: :project_entity,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'My-Destination-Project',
        destination_namespace: group.full_path
      )
    end

    let_it_be_with_reload(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:project_data) do
      {
        'name' => 'Source name',
        'visibility_level' => Gitlab::VisibilityLevel::INTERNAL,
        'created_at' => '2016-08-12T09:41:03',
        'description' => 'description',
        'build_timeout' => 3600,
        'request_access_enabled' => true
      }
    end

    subject(:pipeline) { described_class.new(context) }

    before_all do
      group.add_owner(user)
    end

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::JsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(
          BulkImports::Pipeline::ExtractedData.new(data: project_data)
        )
      end

      allow(pipeline).to receive(:set_source_objects_counter)
    end

    it 'imports new project into destination group', :aggregate_failures do
      expect { pipeline.run }
        .to change { Project.count }.by(1)
        .and change { entity.reload.organization }.to(nil)

      project_path = 'my-destination-project'
      imported_project = Project.find_by_path(project_path)

      expect(imported_project).not_to be_nil
      expect(imported_project.group).to eq(group)
      expect(imported_project.visibility_level).to eq(project_data['visibility_level'])
      expect(imported_project.created_at).to eq(project_data['created_at'])
      expect(imported_project.description).to eq(project_data['description'])
      expect(imported_project.build_timeout).to eq(project_data['build_timeout'])
      expect(imported_project.request_access_enabled).to eq(project_data['request_access_enabled'])
    end

    it 'sets the entity project association', :aggregate_failures do
      pipeline.run

      expect(entity.reload.project).to eq(Project.find_by_path('my-destination-project'))
    end

    it 'skips duplicates on pipeline rerun' do
      expect { pipeline.run }.to change { Project.count }.by(1)
      expect { pipeline.run }.not_to change { Project.count }
    end

    context 'when project creation fails' do
      it 'raises a BulkImports::Error' do
        project = build(:project, namespace: group)
        project.errors.add(:base, 'something went wrong')

        allow_next_instance_of(::Projects::CreateService) do |service|
          allow(service).to receive(:execute).and_return(project)
        end

        expect { pipeline.load(context, {}) }.to raise_error(
          ::BulkImports::Error, /Unable to import project.*something went wrong/
        )
      end
    end
  end

  describe '#load' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:bulk_import) { create(:bulk_import, user: user) }
    let_it_be_with_reload(:entity) do
      create(:bulk_import_entity, :project_entity, bulk_import: bulk_import, destination_namespace: group.full_path)
    end

    let_it_be_with_reload(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let(:context) { BulkImports::Pipeline::Context.new(tracker) }
    let(:data) { { 'default_branch' => 'develop' } }

    subject(:pipeline) { described_class.new(context) }

    before_all do
      group.add_owner(user)
    end

    it 'finalizes attributes that cannot be set via the create service', :aggregate_failures do
      project = create(:project, namespace: group)

      allow_next_instance_of(::Projects::CreateService) do |service|
        allow(service).to receive(:execute).and_return(project)
      end

      expect(project).to receive(:default_branch=).with('develop')
      expect(project).to receive(:reconcile_shared_runners_setting!)
      expect(project).to receive(:save!)

      pipeline.load(context, data)

      expect(project.importing?).to be(true)
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor).to eq(
        klass: BulkImports::Common::Extractors::JsonExtractor,
        options: { relation: 'self' }
      )
    end

    it 'has transformers' do
      expect(described_class.transformers).to contain_exactly(
        { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil },
        { klass: Import::Offline::Projects::Transformers::ProjectAttributesTransformer, options: nil }
      )
    end

    it 'aborts on failure' do
      expect(described_class.abort_on_failure?).to be(true)
    end

    it 'is a file extraction pipeline' do
      expect(described_class.file_extraction_pipeline?).to be(true)
    end

    it 'sets its relation to "self"' do
      expect(described_class.relation).to eq(BulkImports::FileTransfer::BaseConfig::SELF_RELATION)
    end
  end

  describe '#after_run' do
    let_it_be_with_reload(:bulk_import) { create(:bulk_import, user: user) }
    let_it_be(:entity) { create(:bulk_import_entity, :project_entity, bulk_import: bulk_import) }
    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    subject(:pipeline) { described_class.new(context) }

    it 'calls extractor#remove_tmpdir' do
      expect_next_instance_of(BulkImports::Common::Extractors::JsonExtractor) do |extractor|
        expect(extractor).to receive(:remove_tmpdir)
      end

      pipeline.after_run(nil)
    end
  end
end
