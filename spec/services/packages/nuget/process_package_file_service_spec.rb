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

    context 'with valid package file' do
      it 'calls the UpdatePackageFromMetadataService' do
        expect_next_instance_of(Packages::Nuget::UpdatePackageFromMetadataService, package_file,
          instance_of(Zip::File)) do |service|
          expect(service).to receive(:execute)
        end

        subject
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
  end
end
