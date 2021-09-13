# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ProjectPipeline do
  describe '#run' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:bulk_import) { create(:bulk_import, user: user) }

    let_it_be(:entity) do
      create(
        :bulk_import_entity,
        source_type: :project_entity,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_name: 'My Destination Project',
        destination_namespace: group.full_path
      )
    end

    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:project_data) do
      {
        'visibility' => 'private',
        'created_at' => 10.days.ago,
        'archived' => false,
        'shared_runners_enabled' => true,
        'container_registry_enabled' => true,
        'only_allow_merge_if_pipeline_succeeds' => true,
        'only_allow_merge_if_all_discussions_are_resolved' => true,
        'request_access_enabled' => true,
        'printing_merge_request_link_enabled' => true,
        'remove_source_branch_after_merge' => true,
        'autoclose_referenced_issues' => true,
        'suggestion_commit_message' => 'message',
        'wiki_enabled' => true
      }
    end

    subject(:project_pipeline) { described_class.new(context) }

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: project_data))
      end

      group.add_owner(user)
    end

    it 'imports new project into destination group', :aggregate_failures do
      expect { project_pipeline.run }.to change { Project.count }.by(1)

      project_path = 'my-destination-project'
      imported_project = Project.find_by_path(project_path)

      expect(imported_project).not_to be_nil
      expect(imported_project.group).to eq(group)
      expect(imported_project.suggestion_commit_message).to eq('message')
      expect(imported_project.archived?).to eq(project_data['archived'])
      expect(imported_project.shared_runners_enabled?).to eq(project_data['shared_runners_enabled'])
      expect(imported_project.container_registry_enabled?).to eq(project_data['container_registry_enabled'])
      expect(imported_project.only_allow_merge_if_pipeline_succeeds?).to eq(project_data['only_allow_merge_if_pipeline_succeeds'])
      expect(imported_project.only_allow_merge_if_all_discussions_are_resolved?).to eq(project_data['only_allow_merge_if_all_discussions_are_resolved'])
      expect(imported_project.request_access_enabled?).to eq(project_data['request_access_enabled'])
      expect(imported_project.printing_merge_request_link_enabled?).to eq(project_data['printing_merge_request_link_enabled'])
      expect(imported_project.remove_source_branch_after_merge?).to eq(project_data['remove_source_branch_after_merge'])
      expect(imported_project.autoclose_referenced_issues?).to eq(project_data['autoclose_referenced_issues'])
      expect(imported_project.wiki_enabled?).to eq(project_data['wiki_enabled'])
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor)
        .to eq(
          klass: BulkImports::Common::Extractors::GraphqlExtractor,
          options: { query: BulkImports::Projects::Graphql::GetProjectQuery }
        )
    end

    it 'has transformers' do
      expect(described_class.transformers)
        .to contain_exactly(
          { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil },
          { klass: BulkImports::Projects::Transformers::ProjectAttributesTransformer, options: nil }
        )
    end
  end
end
