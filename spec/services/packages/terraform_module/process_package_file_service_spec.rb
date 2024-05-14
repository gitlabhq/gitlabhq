# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::ProcessPackageFileService, feature_category: :package_registry do
  let_it_be(:package_file) { create(:package_file, :terraform_module) }

  subject(:service) { described_class.new(package_file) }

  describe '#execute' do
    shared_examples 'raises an error' do |error_message|
      it { expect { service.execute }.to raise_error(described_class::ExtractionError, error_message) }
    end

    shared_examples 'extracting metadata' do |zip_class|
      it 'calls the ExtractFilesService with the correct arguments' do
        expect_next_instance_of(
          ::Packages::TerraformModule::Metadata::ExtractFilesService,
          instance_of(zip_class)
        ) do |service|
          expect(service).to receive(:execute).and_call_original
        end
        expect_next_instance_of(
          ::Packages::TerraformModule::Metadata::CreateService,
          package_file.package,
          instance_of(Hash)
        ) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        result = service.execute

        expect(result).to be_success
        expect(result.payload).to be_a(Hash)
        expect(Packages::TerraformModule::Metadatum.count).to eq(1)
      end
    end

    context 'with valid package file' do
      context 'with a tar archive' do
        it_behaves_like 'extracting metadata', Gem::Package::TarReader

        context 'with an extraction error' do
          before do
            allow(Zlib::GzipReader).to receive(:open).and_raise(Zlib::GzipFile::Error, 'extraction error')
          end

          it_behaves_like 'raises an error', 'extraction error'
        end
      end

      context 'with a zip archive' do
        let_it_be(:package_file) { create(:package_file, :terraform_module, zip: true) }

        it_behaves_like 'extracting metadata', Zip::File

        context 'with an extraction error' do
          before do
            allow(Zip::File).to receive(:open).and_raise(Zip::Error, 'extraction error')
          end

          it_behaves_like 'raises an error', 'extraction error'
        end
      end
    end

    context 'with invalid package file' do
      let(:package_file) { nil }

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'when linked to a non terraform module package' do
      before do
        package_file.package.maven!
      end

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'with a 0 byte package file' do
      before do
        allow_next_instance_of(Packages::PackageFileUploader) do |instance|
          allow(instance).to receive(:size).and_return(0)
        end
      end

      it_behaves_like 'raises an error', 'invalid package file'
    end
  end
end
