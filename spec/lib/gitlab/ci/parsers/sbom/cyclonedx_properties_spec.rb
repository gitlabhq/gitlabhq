# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::CyclonedxProperties, feature_category: :dependency_management do
  subject(:parse_source_from_properties) { described_class.parse_source(properties) }

  context 'when properties are nil' do
    let(:properties) { nil }

    it { is_expected.to be_nil }
  end

  context 'when report does not have gitlab properties' do
    let(:properties) { ['name' => 'foo', 'value' => 'bar'] }

    it { is_expected.to be_nil }
  end

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

  context 'when no dependency_scanning properties are present' do
    let(:properties) do
      [
        { 'name' => 'gitlab:meta:schema_version', 'value' => '1' }
      ]
    end

    it 'does not call dependency_scanning parser' do
      expect(Gitlab::Ci::Parsers::Sbom::Source::DependencyScanning).not_to receive(:source)

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
end
