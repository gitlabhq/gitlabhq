# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::RepositoryPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:parent) { create(:project) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:bulk_import_configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Repository',
      destination_namespace: parent.full_path,
      project: parent
    )
  end

  let_it_be_with_reload(:tracker) { create(:bulk_import_tracker, entity: entity) }

  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:extracted_data) { BulkImports::Pipeline::ExtractedData.new(data: project_data) }

  subject(:pipeline) { described_class.new(context) }

  before do
    allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(extracted_data)
    end

    allow(pipeline).to receive(:set_source_objects_counter)
  end

  describe '#run' do
    context 'successfully imports repository' do
      let(:project_data) { { 'httpUrlToRepo' => 'http://test.git' } }

      it 'imports new repository into destination project' do
        url = project_data['httpUrlToRepo'].sub("://", "://oauth2:#{bulk_import_configuration.access_token}@")

        expect(context.portable).to receive(:ensure_repository)
        expect(context.portable.repository).to receive(:fetch_as_mirror).with(url)

        pipeline.run
      end
    end

    context 'project has no repository' do
      let(:project_data) { { 'httpUrlToRepo' => '' } }

      it 'skips repository import' do
        expect(context.portable).not_to receive(:ensure_repository)
        expect(context.portable.repository).not_to receive(:fetch_as_mirror)

        pipeline.run
      end
    end

    context 'blocked local networks' do
      let(:project_data) { { 'httpUrlToRepo' => 'http://localhost/foo.git' } }

      it 'prevents import' do
        allow(Gitlab.config.gitlab).to receive(:host).and_return('notlocalhost.gitlab.com')
        allow(Gitlab::CurrentSettings).to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(false)

        pipeline.run

        expect(context.entity.failed?).to eq(true)
      end
    end

    context 'when scheme is blocked' do
      let(:project_data) { { 'httpUrlToRepo' => 'file://example/tmp/foo.git' } }

      it 'prevents import' do
        pipeline.run

        expect(context.entity.failed?).to eq(true)
        expect(context.entity.failures.first).to be_present
        expect(context.entity.failures.first.exception_message).to eq('Only allowed schemes are http, https')
      end
    end
  end

  describe '#after_run' do
    it 'executes housekeeping service after import' do
      service = instance_double(::Repositories::HousekeepingService)

      expect(::Repositories::HousekeepingService).to receive(:new).with(context.portable, :gc).and_return(service)
      expect(service).to receive(:execute)

      pipeline.after_run(context)
    end
  end
end
