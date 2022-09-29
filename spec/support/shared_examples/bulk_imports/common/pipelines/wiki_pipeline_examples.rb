# frozen_string_literal: true

RSpec.shared_examples 'wiki pipeline imports a wiki for an entity' do
  describe '#run' do
    let_it_be(:bulk_import_configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }

    let_it_be_with_reload(:tracker) { create(:bulk_import_tracker, entity: entity) }

    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:extracted_data) { BulkImports::Pipeline::ExtractedData.new(data: {}) }

    subject { described_class.new(context) }

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(extracted_data)
      end
    end

    context 'when wiki exists' do
      it 'imports new wiki into destination project' do
        expect(subject).to receive(:source_wiki_exists?).and_return(true)

        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |repository_service|
          url = "https://oauth2:token@gitlab.example/#{entity.source_full_path}.wiki.git"
          expect(repository_service).to receive(:fetch_remote).with(url, any_args).and_return 0
        end

        subject.run
      end
    end

    context 'when wiki does not exist' do
      it 'does not import wiki' do
        expect(subject).to receive(:source_wiki_exists?).and_return(false)

        expect(parent.wiki).not_to receive(:ensure_repository)
        expect(parent.wiki.repository).not_to receive(:ensure_repository)

        expect { subject.run }.not_to raise_error
      end
    end

    context 'when scheme is blocked' do
      it 'prevents import' do
        # Force bulk_import_configuration to have a file:// URL
        bulk_import_configuration.url = 'file://example.com'
        bulk_import_configuration.save!(validate: false)

        expect(subject).to receive(:source_wiki_exists?).and_return(true)

        subject.run

        expect(tracker.failed?).to eq(true)
        expect(tracker.entity.failures.first).to be_present
        expect(tracker.entity.failures.first.exception_message).to eq('Only allowed schemes are http, https')
      end
    end
  end
end
