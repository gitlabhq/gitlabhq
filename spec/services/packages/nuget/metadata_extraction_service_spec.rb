# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::MetadataExtractionService, feature_category: :package_registry do
  let_it_be(:package_file) { create(:nuget_package).package_files.first }

  subject { described_class.new(package_file) }

  describe '#execute' do
    let(:nuspec_file_content) do
      <<~XML.squish
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
      expect(::Packages::Nuget::ExtractMetadataFileService).to receive(:new).with(package_file) do
        double.tap do |service|
          expect(service).to receive(:execute).and_return(double(payload: nuspec_file_content))
        end
      end

      expect(::Packages::Nuget::ExtractMetadataContentService).to receive_message_chain(:new, :execute)
        .with(nuspec_file_content).with(no_args).and_return(double(payload: expected_metadata))

      metadata = subject.execute.payload

      expect(metadata).to eq(expected_metadata)
    end
  end
end
