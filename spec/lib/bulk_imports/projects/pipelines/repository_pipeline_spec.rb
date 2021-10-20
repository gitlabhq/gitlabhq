# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::RepositoryPipeline do
  describe '#run' do
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
        destination_name: 'My Destination Repository',
        destination_namespace: parent.full_path,
        project: parent
      )
    end

    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    context 'successfully imports repository' do
      let(:project_data) do
        {
          'httpUrlToRepo' => 'http://test.git'
        }
      end

      subject { described_class.new(context) }

      it 'imports new repository into destination project' do
        allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
          allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: project_data))
        end

        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |repository_service|
          url = project_data['httpUrlToRepo'].sub("://", "://oauth2:#{bulk_import_configuration.access_token}@")
          expect(repository_service).to receive(:import_repository).with(url).and_return 0
        end

        subject.run
      end
    end

    context 'blocked local networks' do
      let(:project_data) do
        {
          'httpUrlToRepo' => 'http://localhost/foo.git'
        }
      end

      before do
        allow(Gitlab.config.gitlab).to receive(:host).and_return('notlocalhost.gitlab.com')
        allow(Gitlab::CurrentSettings).to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(false)
        allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
          allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: project_data))
        end
      end

      subject { described_class.new(context) }

      it 'imports new repository into destination project' do
        subject.run
        expect(context.entity.failed?).to be_truthy
      end
    end
  end
end
