# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::CyclonedxProperties, feature_category: :dependency_management do
  shared_examples 'handling invalid properties' do
    context 'when properties are nil' do
      let(:properties) { nil }

      it { is_expected.to be_nil }
    end

    context 'when report does not have valid properties' do
      let(:properties) { ['name' => 'foo', 'value' => 'bar'] }

      it { is_expected.to be_nil }
    end
  end

  describe '#parse_source' do
    subject(:parse_source_from_properties) { described_class.parse_source(properties) }

    it_behaves_like 'handling invalid properties'

    context 'when schema_version is missing' do
      let(:properties) do
        [
          { 'name' => 'gitlab:dependency_scanning:dependency_file', 'value' => 'package-lock.json' },
          { 'name' => 'gitlab:dependency_scanning:package_manager_name', 'value' => 'npm' },
          { 'name' => 'gitlab:dependency_scanning:language', 'value' => 'JavaScript' }
        ]
      end

      it { is_expected.to be_nil }
    end

    context 'when schema version is unsupported' do
      let(:properties) do
        [
          { 'name' => 'gitlab:meta:schema_version', 'value' => '2' },
          { 'name' => 'gitlab:dependency_scanning:dependency_file', 'value' => 'package-lock.json' },
          { 'name' => 'gitlab:dependency_scanning:package_manager_name', 'value' => 'npm' },
          { 'name' => 'gitlab:dependency_scanning:language', 'value' => 'JavaScript' }
        ]
      end

      it { is_expected.to be_nil }
    end

    context 'when no dependency_scanning, container_scanning, container_scanning_for_registry properties are present' do
      let(:properties) do
        [
          { 'name' => 'gitlab:meta:schema_version', 'value' => '1' },
          { 'name' => 'gitlab::aquasecurity:trivy:FilePath', 'value' => '1' }
        ]
      end

      it 'does not call source parsers' do
        expect(Gitlab::Ci::Parsers::Sbom::Source::DependencyScanning).not_to receive(:source)
        expect(Gitlab::Ci::Parsers::Sbom::Source::ContainerScanning).not_to receive(:source)
        expect(Gitlab::Ci::Parsers::Sbom::Source::ContainerScanningForRegistry).not_to receive(:source)

        parse_source_from_properties
      end
    end

    context 'when dependency_scanning properties are present' do
      let(:properties) do
        [
          { 'name' => 'gitlab:meta:schema_version', 'value' => '1' },
          { 'name' => 'gitlab:dependency_scanning:category', 'value' => 'development' },
          { 'name' => 'gitlab:dependency_scanning:input_file:path', 'value' => 'package-lock.json' },
          { 'name' => 'gitlab:dependency_scanning:source_file:path', 'value' => 'package.json' },
          { 'name' => 'gitlab:dependency_scanning:package_manager:name', 'value' => 'npm' },
          { 'name' => 'gitlab:dependency_scanning:language:name', 'value' => 'JavaScript' },
          { 'name' => 'gitlab:dependency_scanning:unsupported_property', 'value' => 'Should be ignored' }
        ]
      end

      let(:expected_input) do
        {
          'category' => 'development',
          'input_file' => { 'path' => 'package-lock.json' },
          'source_file' => { 'path' => 'package.json' },
          'package_manager' => { 'name' => 'npm' },
          'language' => { 'name' => 'JavaScript' }
        }
      end

      it 'passes only supported properties to the dependency scanning parser' do
        expect(Gitlab::Ci::Parsers::Sbom::Source::DependencyScanning).to receive(:source).with(expected_input)

        parse_source_from_properties
      end
    end

    context 'when container_scanning properties are present' do
      let(:properties) do
        [
          { 'name' => 'gitlab:meta:schema_version', 'value' => '1' },
          { 'name' => 'gitlab:container_scanning:image:name', 'value' => 'photon' },
          { 'name' => 'gitlab:container_scanning:image:tag', 'value' => '5.0-20231007' },
          { 'name' => 'gitlab:container_scanning:operating_system:name', 'value' => 'Photon OS' },
          { 'name' => 'gitlab:container_scanning:operating_system:version', 'value' => '5.0' }
        ]
      end

      let(:expected_input) do
        {
          'image' => {
            'name' => 'photon',
            'tag' => '5.0-20231007'
          },
          'operating_system' => {
            'name' => 'Photon OS',
            'version' => '5.0'
          }
        }
      end

      it 'passes only supported properties to the container scanning parser' do
        expect(Gitlab::Ci::Parsers::Sbom::Source::ContainerScanning).to receive(:source).with(expected_input)

        parse_source_from_properties
      end
    end

    context 'when container_scanning_for_registry properties are present' do
      let(:properties) do
        [
          { 'name' => 'gitlab:meta:schema_version', 'value' => '1' },
          { 'name' => 'gitlab:container_scanning_for_registry:image:name', 'value' => 'photon' },
          { 'name' => 'gitlab:container_scanning_for_registry:image:tag', 'value' => '5.0-20231007' },
          { 'name' => 'gitlab:container_scanning_for_registry:operating_system:name', 'value' => 'Photon OS' },
          { 'name' => 'gitlab:container_scanning_for_registry:operating_system:version', 'value' => '5.0' }
        ]
      end

      let(:expected_input) do
        {
          'image' => {
            'name' => 'photon',
            'tag' => '5.0-20231007'
          },
          'operating_system' => {
            'name' => 'Photon OS',
            'version' => '5.0'
          }
        }
      end

      it 'passes only supported properties to the container scanning for registry parser' do
        expect(Gitlab::Ci::Parsers::Sbom::Source::ContainerScanningForRegistry).to receive(:source).with(expected_input)

        parse_source_from_properties
      end
    end
  end

  describe '#parse_component_source' do
    subject(:parse_component_source_from_properties) { described_class.parse_component_source(properties) }

    it_behaves_like 'handling invalid properties'

    context 'when no trivy properties are present' do
      let(:properties) do
        [
          { 'name' => 'gitlab:meta:schema_version', 'value' => '1' },
          { 'name' => 'gitlab::aquasecurity:trivy:FilePath', 'value' => '1' }
        ]
      end

      it 'does not call source parsers' do
        expect(Gitlab::Ci::Parsers::Sbom::Source::Trivy).not_to receive(:source)

        parse_component_source_from_properties
      end
    end

    context 'when trivy properties are present' do
      let(:properties) do
        [
          { 'name' => 'aquasecurity:trivy:PkgID', 'value' => 'sha256:47ce8fad8..' },
          { 'name' => 'aquasecurity:trivy:LayerDigest',
            'value' => 'registry.test.com/atiwari71/container-scanning-test/main@sha256:e14a4bcf..' },
          { 'name' => 'aquasecurity:trivy:LayerDiffID', 'value' => 'sha256:94dd7d531fa..' },
          { 'name' => 'aquasecurity:trivy:SrcEpoch', 'value' => 'sha256:5d20c808c..' }
        ]
      end

      let(:expected_input) do
        {
          'PkgID' => 'sha256:47ce8fad8..',
          'LayerDigest' => 'registry.test.com/atiwari71/container-scanning-test/main@sha256:e14a4bcf..',
          'LayerDiffID' => 'sha256:94dd7d531fa..',
          'SrcEpoch' => 'sha256:5d20c808c..'
        }
      end

      it 'passes only supported properties to the trivy parser' do
        expect(Gitlab::Ci::Parsers::Sbom::Source::Trivy).to receive(:source).with(expected_input)

        parse_component_source_from_properties
      end
    end

    context 'when dependency_scanning_component properties are present' do
      let(:properties) do
        [
          { 'name' => 'gitlab:dependency_scanning_component:reachability', 'value' => 'unknown' }
        ]
      end

      let(:expected_input) do
        {
          'reachability' => 'unknown'
        }
      end

      it 'passes only supported properties to the container scanning for registry parser' do
        expect(Gitlab::Ci::Parsers::Sbom::Source::DependencyScanningComponent).to receive(:source).with(expected_input)

        parse_component_source_from_properties
      end
    end
  end
end
