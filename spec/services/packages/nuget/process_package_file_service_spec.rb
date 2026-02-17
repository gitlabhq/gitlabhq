# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::ProcessPackageFileService, feature_category: :package_registry do
  # Use `let` with `build` - non-persisted objects don't benefit from `let_it_be`.
  let(:package_file) { build(:package_file, :nuget) }

  let(:service) { described_class.new(package_file) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'raises an error' do |error_message|
      it { expect { subject }.to raise_error(described_class::ExtractionError, error_message) }
    end

    context 'with valid package file' do
      it 'calls the UpdatePackageFromMetadataService' do
        expect_next_instance_of(Packages::Nuget::UpdatePackageFromMetadataService, package_file,
          instance_of(Zip::File), nil) do |service|
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
      let(:package_file) { build(:package_file, :nuget, package: build(:maven_package)) }

      it_behaves_like 'raises an error', 'invalid package file'
    end

    context 'with a 0 byte package file' do
      let(:package_file) { build(:package_file, :nuget) }

      before do
        allow_next_instance_of(Packages::PackageFileUploader) do |instance|
          allow(instance).to receive(:size).and_return(0)
        end
      end

      it_behaves_like 'raises an error', 'invalid package file'
    end
  end
end
