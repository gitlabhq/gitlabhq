# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::ExtractMetadataFileService, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers

  let_it_be(:package_file) { build(:package_file, :nuget) }
  let_it_be(:package_zip_file) { Zip::File.new(package_file.file) }

  let(:service) { described_class.new(package_zip_file) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'raises an error' do |error_message|
      it { expect { subject }.to raise_error(described_class::ExtractionError, error_message) }
    end

    context 'with valid package file' do
      expected_metadata = <<~XML.squish
        <package xmlns="http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd">
          <metadata>
            <id>DummyProject.DummyPackage</id>
            <version>1.0.0</version>
            <title>Dummy package</title>
            <authors>Test</authors>
            <owners>Test</owners>
            <requireLicenseAcceptance>false</requireLicenseAcceptance>
            <description>This is a dummy project</description>
            <dependencies>
              <group targetFramework=".NETCoreApp3.0">
                <dependency id="Newtonsoft.Json" version="12.0.3" exclude="Build,Analyzers" />
              </group>
            </dependencies>
          </metadata>
        </package>
      XML

      it 'returns the nuspec file content' do
        expect(subject.payload.squish).to include(expected_metadata)
      end

      context 'with InputStream zip' do
        let(:package_zip_file) do
          Zip::InputStream.open(
            temp_file('package.nupkg', content: File.open(package_file.file.path))
          )
        end

        it 'returns the nuspec file content' do
          expect(subject.payload.squish).to include(expected_metadata)
        end
      end
    end

    context 'without the nuspec file' do
      before do
        allow(package_zip_file).to receive(:glob).and_return([])
      end

      it_behaves_like 'raises an error', 'nuspec file not found'
    end

    context 'with a too big nuspec file' do
      before do
        allow(package_zip_file).to receive(:glob).and_return(
          [instance_double(File, size: described_class::MAX_FILE_SIZE + 1)]
        )
      end

      it_behaves_like 'raises an error', 'nuspec file too big'
    end

    context 'with a corrupted nupkg file with a wrong entry size' do
      let(:nupkg_fixture_path) { expand_fixture_path('packages/nuget/corrupted_package.nupkg') }
      let(:package_zip_file) { Zip::File.new(nupkg_fixture_path) }

      it_behaves_like 'raises an error',
        <<~ERROR.squish
          nuspec file has the wrong entry size: entry 'DummyProject.DummyPackage.nuspec' should be 255B,
          but is larger when inflated.
        ERROR
    end
  end
end
