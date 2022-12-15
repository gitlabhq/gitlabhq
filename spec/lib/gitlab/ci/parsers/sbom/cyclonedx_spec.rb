# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::Cyclonedx, feature_category: :dependency_management do
  let(:report) { instance_double('Gitlab::Ci::Reports::Sbom::Report') }
  let(:report_data) { base_report_data }
  let(:raw_report_data) { report_data.to_json }
  let(:report_valid?) { true }
  let(:validator_errors) { [] }
  let(:properties_parser) { class_double('Gitlab::Ci::Parsers::Sbom::CyclonedxProperties') }

  let(:base_report_data) do
    {
      'bomFormat' => 'CycloneDX',
      'specVersion' => '1.4',
      'version' => 1
    }
  end

  subject(:parse!) { described_class.new.parse!(raw_report_data, report) }

  before do
    allow_next_instance_of(Gitlab::Ci::Parsers::Sbom::Validators::CyclonedxSchemaValidator) do |validator|
      allow(validator).to receive(:valid?).and_return(report_valid?)
      allow(validator).to receive(:errors).and_return(validator_errors)
    end

    allow(properties_parser).to receive(:parse_source)
    stub_const('Gitlab::Ci::Parsers::Sbom::CyclonedxProperties', properties_parser)
  end

  context 'when report JSON is invalid' do
    let(:raw_report_data) { '{ ' }

    it 'handles errors and adds them to the report' do
      expect(report).to receive(:add_error).with(a_string_including("Report JSON is invalid:"))

      expect { parse! }.not_to raise_error
    end
  end

  context 'when report uses an unsupported spec version' do
    let(:report_data) { base_report_data.merge({ 'specVersion' => '1.3' }) }

    it 'reports unsupported version as an error' do
      expect(report).to receive(:add_error).with("Unsupported CycloneDX spec version. Must be one of: 1.4")

      parse!
    end
  end

  context 'when report does not conform to the CycloneDX schema' do
    let(:report_valid?) { false }
    let(:validator_errors) { %w[error1 error2] }

    it 'reports all errors returned by the validator' do
      expect(report).to receive(:add_error).with("error1")
      expect(report).to receive(:add_error).with("error2")

      parse!
    end
  end

  context 'when cyclonedx report has no components' do
    it 'skips component processing' do
      expect(report).not_to receive(:add_component)

      parse!
    end
  end

  context 'when report has components' do
    let(:report_data) { base_report_data.merge({ 'components' => components }) }
    let(:components) do
      [
        {
          "name" => "activesupport",
          "version" => "5.1.4",
          "purl" => "pkg:gem/activesupport@5.1.4",
          "type" => "library",
          "bom-ref" => "pkg:gem/activesupport@5.1.4"
        },
        {
          "name" => "byebug",
          "version" => "10.0.0",
          "purl" => "pkg:gem/byebug@10.0.0",
          "type" => "library",
          "bom-ref" => "pkg:gem/byebug@10.0.0"
        },
        {
          "name" => "minimal-component",
          "type" => "library"
        },
        {
          # Should be skipped
          "name" => "unrecognized-type",
          "type" => "unknown"
        }
      ]
    end

    before do
      allow(report).to receive(:add_component)
    end

    it 'adds each component, ignoring unused attributes' do
      expect(report).to receive(:add_component)
        .with(
          an_object_having_attributes(
            name: "activesupport",
            version: "5.1.4",
            component_type: "library",
            purl: an_object_having_attributes(type: "gem")
          )
        )
      expect(report).to receive(:add_component)
        .with(
          an_object_having_attributes(
            name: "byebug",
            version: "10.0.0",
            component_type: "library",
            purl: an_object_having_attributes(type: "gem")
          )
        )
      expect(report).to receive(:add_component)
        .with(an_object_having_attributes(name: "minimal-component", version: nil, component_type: "library"))

      parse!
    end

    context 'when a component has an invalid purl' do
      before do
        components.push(
          {
            "name" => "invalid-component",
            "version" => "v0.0.1",
            "purl" => "pkg:nil",
            "type" => "library"
          }
        )
      end

      it 'adds an error to the report' do
        expect(report).to receive(:add_error).with("/components/#{components.size - 1}/purl is invalid")

        parse!
      end
    end
  end

  context 'when report has metadata properties' do
    let(:report_data) { base_report_data.merge({ 'metadata' => { 'properties' => properties } }) }

    let(:properties) do
      [
        { 'name' => 'gitlab:meta:schema_version', 'value' => '1' },
        { 'name' => 'gitlab:dependency_scanning:category', 'value' => 'development' },
        { 'name' => 'gitlab:dependency_scanning:input_file:path', 'value' => 'package-lock.json' },
        { 'name' => 'gitlab:dependency_scanning:source_file:path', 'value' => 'package.json' },
        { 'name' => 'gitlab:dependency_scanning:package_manager:name', 'value' => 'npm' },
        { 'name' => 'gitlab:dependency_scanning:language:name', 'value' => 'JavaScript' }
      ]
    end

    it 'passes them to the properties parser' do
      expect(properties_parser).to receive(:parse_source).with(properties)

      parse!
    end
  end
end
