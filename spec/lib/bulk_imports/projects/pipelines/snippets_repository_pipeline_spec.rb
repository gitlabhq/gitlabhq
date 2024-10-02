# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::SnippetsRepositoryPipeline, feature_category: :importers do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:bulk_import) { create(:bulk_import, user: user) }
  let(:bulk_import_configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let!(:matched_snippet) { create(:project_snippet, project: project, created_at: "1981-12-13T23:59:59Z") }
  let(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import_configuration.bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Project',
      destination_namespace: project.full_path
    )
  end

  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:pipeline) { described_class.new(context) }

  let(:http_url_to_repo) { 'https://example.com/foo/bar/snippets/42.git' }
  let(:data) do
    [
      {
        'title' => matched_snippet.title,
        'httpUrlToRepo' => http_url_to_repo,
        'createdAt' => matched_snippet.created_at.to_s
      }
    ]
  end

  let(:page_info) do
    {
      'next_page' => 'eyJpZCI6IjIyMDA2OTYifQ',
      'has_next_page' => false
    }
  end

  let(:extracted_data) { BulkImports::Pipeline::ExtractedData.new(data: data, page_info: page_info) }

  before do
    allow(pipeline).to receive(:set_source_objects_counter)
  end

  describe 'extractor' do
    it 'is a GraphqlExtractor with Graphql::GetSnippetRepositoryQuery' do
      expect(described_class.get_extractor).to eq(
        klass: BulkImports::Common::Extractors::GraphqlExtractor,
        options: {
          query: BulkImports::Projects::Graphql::GetSnippetRepositoryQuery
        })
    end
  end

  describe '#run', :clean_gitlab_redis_shared_state do
    let(:validation_response) { double(Hash, error?: false) }

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(extracted_data)
      end

      allow_next_instance_of(Snippets::RepositoryValidationService) do |repository_validation|
        allow(repository_validation).to receive(:execute).and_return(validation_response)
      end
    end

    shared_examples 'skippable snippet' do
      it 'does not create snippet repo' do
        pipeline.run

        expect(Gitlab::GlRepository::SNIPPET.repository_for(matched_snippet).exists?).to be false
      end
    end

    context 'when a snippet is not matched' do
      let(:data) do
        [
          {
            'title' => 'unmatched title',
            'httpUrlToRepo' => http_url_to_repo,
            'createdAt' => matched_snippet.created_at.to_s
          }
        ]
      end

      it_behaves_like 'skippable snippet'
    end

    context 'when httpUrlToRepo is empty' do
      let(:data) do
        [
          {
            'title' => matched_snippet.title,
            'createdAt' => matched_snippet.created_at.to_s
          }
        ]
      end

      it_behaves_like 'skippable snippet'
    end

    context 'when a snippet matches' do
      context 'when snippet url is valid' do
        it 'creates snippet repo' do
          expect { pipeline.run }
            .to change { Gitlab::GlRepository::SNIPPET.repository_for(matched_snippet).exists? }.to true
        end

        it 'skips already cached snippets' do
          pipeline.run

          data.first.tap { |d| d['createdAt'] = matched_snippet.created_at.to_s } # Reset data to original state

          expect(pipeline).not_to receive(:load)

          pipeline.run

          expect(Gitlab::GlRepository::SNIPPET.repository_for(matched_snippet).exists?).to be true
        end

        it 'updates snippets statistics' do
          allow_next_instance_of(Repository) do |repository|
            allow(repository).to receive(:fetch_as_mirror)
          end

          service = double(Snippets::UpdateStatisticsService)

          expect(Snippets::UpdateStatisticsService).to receive(:new).with(kind_of(Snippet)).and_return(service)
          expect(service).to receive(:execute)

          pipeline.run
        end

        it 'fetches snippet repo from url' do
          expect_next_instance_of(Repository) do |repository|
            expect(repository)
              .to receive(:fetch_as_mirror)
              .with("https://oauth2:#{bulk_import_configuration.access_token}@example.com/foo/bar/snippets/42.git")
          end

          pipeline.run
        end
      end

      context 'when url is invalid' do
        context 'when not a real URL' do
          let(:http_url_to_repo) { 'http://0.0.0.0' }

          it_behaves_like 'skippable snippet'
        end

        context 'when scheme is blocked' do
          let(:http_url_to_repo) { 'file://example.com/foo/bar/snippets/42.git' }

          it_behaves_like 'skippable snippet'

          it 'logs the failure' do
            pipeline.run

            expect(tracker.entity.failures.first).to be_present
            expect(tracker.entity.failures.first.exception_message).to eq('Only allowed schemes are http, https')
          end
        end
      end

      context 'when snippet is invalid' do
        let(:validation_response) { double(Hash, error?: true) }

        before do
          allow_next_instance_of(Repository) do |repository|
            allow(repository).to receive(:fetch_as_mirror)
          end
        end

        it 'does not leave a hanging SnippetRepository behind' do
          pipeline.run

          expect(SnippetRepository.where(snippet_id: matched_snippet.id).exists?).to be false
        end

        it 'does not call UpdateStatisticsService' do
          expect(Snippets::UpdateStatisticsService).not_to receive(:new)

          pipeline.run
        end

        it_behaves_like 'skippable snippet'
      end
    end
  end
end
