# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::MetadataExtractionService, feature_category: :package_registry do
  let_it_be(:package_file) { build(:package_file, :nuget) }
  let(:package_zip_file) { Zip::File.new(package_file.file) }
  let(:service) { described_class.new(package_zip_file) }

  describe '#execute' do
    subject { service.execute }

    let(:nuspec_file_content) do
      <<~XML
        <?xml version="1.0" encoding="utf-8"?>
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
    end

    let(:expected_metadata) do
      {
        package_name: 'DummyProject.DummyPackage',
        package_version: '1.0.0',
        authors: 'Test',
        description: 'This is a dummy project',
        package_dependencies: [
          {
            name: 'Newtonsoft.Json',
            target_framework: '.NETCoreApp3.0',
            version: '12.0.3'
          }
        ],
        package_tags: [],
        package_types: []
      }
    end

    it 'calls the necessary services and executes the metadata extraction' do
      expect_next_instance_of(Packages::Nuget::ExtractMetadataFileService, package_zip_file) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success(payload: nuspec_file_content))
      end

      expect_next_instance_of(Packages::Nuget::ExtractMetadataContentService, nuspec_file_content) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      expect(subject.payload).to eq(expected_metadata)
    end
  end
end
