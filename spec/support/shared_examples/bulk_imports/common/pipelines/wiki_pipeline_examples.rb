# frozen_string_literal: true

RSpec.shared_examples 'wiki pipeline imports a wiki for an entity' do
  describe '#run' do
    let_it_be(:bulk_import_configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }

    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:extracted_data) { BulkImports::Pipeline::ExtractedData.new(data: {}) }

    context 'successfully imports wiki for an entity' do
      subject { described_class.new(context) }

      before do
        allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
          allow(extractor).to receive(:extract).and_return(extracted_data)
        end
      end

      it 'imports new wiki into destination project' do
        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |repository_service|
          url = "https://oauth2:token@gitlab.example/#{entity.source_full_path}.wiki.git"
          expect(repository_service).to receive(:fetch_remote).with(url, any_args).and_return 0
        end

        subject.run
      end
    end
  end
end
