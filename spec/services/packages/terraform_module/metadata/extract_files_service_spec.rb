# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Metadata::ExtractFilesService, feature_category: :package_registry do
  subject(:service) { described_class.new(archive_file) }

  describe '#execute' do
    shared_examples 'extracting metadata' do |file_names|
      it 'successfully extracts metadata from archive' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload).to be_a(Hash)
        expect(result.payload.keys).to match_array(file_names)
      end
    end

    context 'when processing a tar archive' do
      let_it_be(:package_file) { create(:package_file, :terraform_module) }
      let_it_be(:archive_file) { Gem::Package::TarReader.new(Zlib::GzipReader.open(package_file.file.path)) }

      it_behaves_like 'extracting metadata', %w[./README.md ./main.tf ./variables.tf ./outputs.tf]

      context 'with a wrong entry size' do
        before do
          allow(File).to receive(:size).and_return(described_class::MAX_FILE_SIZE + 1)
        end

        it 'raises an ExtractionError' do
          expect do
            service.execute
          end.to raise_error(described_class::ExtractionError, /metadata file has the wrong entry size/)
        end
      end
    end

    context 'when processing a zip archive' do
      let_it_be(:package_file) { create(:package_file, :terraform_module, zip: true) }
      let(:archive_file) { Zip::File.open(package_file.file.path) }

      it_behaves_like 'extracting metadata', %w[README.md main.tf variables.tf outputs.tf]

      context 'with a wrong entry size' do
        before do
          allow_next_instance_of(Zip::Entry) do |instance|
            allow(instance).to receive(:extract).and_raise(Zip::EntrySizeError)
          end
        end

        it 'raises an ExtractionError' do
          expect do
            service.execute
          end.to raise_error(described_class::ExtractionError, /metadata file has the wrong entry size/)
        end
      end
    end
  end
end
