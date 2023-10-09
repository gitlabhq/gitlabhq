# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::ProcessPackageFileService, feature_category: :package_registry do
  let_it_be(:package_file) { build(:package_file, :nuget) }

  let(:service) { described_class.new(package_file) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'raises an error' do |error_message|
      it { expect { subject }.to raise_error(described_class::ExtractionError, error_message) }
    end

    shared_examples 'not creating a symbol file' do
      it 'does not call the CreateSymbolFilesService' do
        expect(Packages::Nuget::Symbols::CreateSymbolFilesService).not_to receive(:new)

        expect(subject).to be_success
      end
    end

    context 'with valid package file' do
      it 'calls the ExtractMetadataFileService' do
        expect_next_instance_of(Packages::Nuget::ExtractMetadataFileService, instance_of(Zip::File)) do |service|
          expect(service).to receive(:execute) do
            instance_double(ServiceResponse).tap do |response|
              expect(response).to receive(:payload).and_return(instance_of(String))
            end
          end
        end

        expect(subject).to be_success
      end
    end

    context 'with invalid package file' do
      let(:package_file) { nil }

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'when linked to a non nuget package' do
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

    context 'with a symbol package file' do
      let(:package_file) { build(:package_file, :snupkg) }

      it 'calls the CreateSymbolFilesService' do
        expect_next_instance_of(
          Packages::Nuget::Symbols::CreateSymbolFilesService, package_file.package, instance_of(Zip::File)
        ) do |service|
          expect(service).to receive(:execute)
        end

        expect(subject).to be_success
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(index_nuget_symbol_files: false)
        end

        it_behaves_like 'not creating a symbol file'
      end
    end

    context 'with a non symbol package file' do
      let(:package_file) { build(:package_file, :nuget) }

      it_behaves_like 'not creating a symbol file'
    end
  end
end
