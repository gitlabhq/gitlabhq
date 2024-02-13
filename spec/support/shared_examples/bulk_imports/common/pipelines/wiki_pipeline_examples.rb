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

      allow(subject).to receive(:set_source_objects_counter)
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

        expect(parent.wiki).not_to receive(:create_wiki_repository)
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

        expect(tracker.entity.failures.first).to be_present
        expect(tracker.entity.failures.first.exception_message).to eq('Only allowed schemes are http, https')
      end
    end

    context 'when wiki is disabled' do
      before do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
          allow(client)
            .to receive(:get)
            .and_raise(
              BulkImports::NetworkError.new(
                'Unsuccessful response 403 from ...',
                response: response_double
              )
            )
        end
      end

      describe 'unsuccessful response' do
        shared_examples 'does not raise an error' do
          it 'does not raise an error' do
            expect(parent.wiki).not_to receive(:create_wiki_repository)
            expect(parent.wiki.repository).not_to receive(:ensure_repository)

            expect { subject.run }.not_to raise_error
          end
        end

        context 'when response is forbidden' do
          let(:response_double) { instance_double(HTTParty::Response, forbidden?: true, code: 403) }

          include_examples 'does not raise an error'
        end

        context 'when response is not found' do
          let(:response_double) { instance_double(HTTParty::Response, forbidden?: false, not_found?: true) }

          include_examples 'does not raise an error'
        end

        context 'when response is not 403' do
          let(:response_double) { instance_double(HTTParty::Response, forbidden?: false, not_found?: false, code: 301) }

          include_examples 'does not raise an error'
        end
      end
    end
  end
end
