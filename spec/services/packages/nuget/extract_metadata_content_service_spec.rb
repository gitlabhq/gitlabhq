# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::ExtractMetadataContentService, feature_category: :package_registry do
  let(:nuspec_file_content) { fixture_file(nuspec_filepath) }

  let(:service) { described_class.new(nuspec_file_content) }

  describe '#execute' do
    subject { service.execute.payload }

    context 'with nuspec file content' do
      context 'with dependencies' do
        let(:nuspec_filepath) { 'packages/nuget/with_dependencies.nuspec' }

        it { is_expected.to have_key(:package_dependencies) }

        it 'extracts dependencies' do
          dependencies = subject[:package_dependencies]

          expect(dependencies).to include(name: 'Moqi', version: '2.5.6')
            .and include(name: 'Castle.Core')
            .and include(name: 'Test.Dependency', version: '2.3.7', target_framework: '.NETStandard2.0')
            .and include(name: 'Newtonsoft.Json', version: '12.0.3', target_framework: '.NETStandard2.0')
        end
      end

      context 'with package types' do
        let(:nuspec_filepath) { 'packages/nuget/with_package_types.nuspec' }

        it { is_expected.to have_key(:package_types) }

        it 'extracts package types' do
          expect(subject[:package_types]).to include('SymbolsPackage')
        end
      end

      context 'with a nuspec file with metadata' do
        let(:nuspec_filepath) { 'packages/nuget/with_metadata.nuspec' }

        it { expect(subject[:package_tags].sort).to eq(%w[foo bar test tag1 tag2 tag3 tag4 tag5].sort) }
      end
    end

    context 'with a nuspec file content with metadata' do
      let_it_be(:nuspec_filepath) { 'packages/nuget/with_metadata.nuspec' }

      it 'returns the correct metadata' do
        expected_metadata = {
          authors: 'Author Test',
          description: 'Description Test',
          license_url: 'https://opensource.org/licenses/MIT',
          project_url: 'https://gitlab.com/gitlab-org/gitlab',
          icon_url: 'https://opensource.org/files/osi_keyhole_300X300_90ppi_0.png'
        }

        expect(subject.slice(*expected_metadata.keys)).to eq(expected_metadata)
      end
    end
  end
end
