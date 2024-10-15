# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::Cyclonedx, feature_category: :dependency_management do
  let(:report) { Gitlab::Ci::Reports::Sbom::Report.new }
  let(:report_data) { base_report_data }
  let(:raw_report_data) { report_data.to_json }
  let(:report_valid?) { true }
  let(:validator_errors) { [] }
  let(:properties_parser) { Gitlab::Ci::Parsers::Sbom::CyclonedxProperties }
  let(:uuid) { 'c9d550a3-feb8-483b-a901-5aa892d039f9' }

  let(:base_report_data) do
    {
      'bomFormat' => 'CycloneDX',
      'specVersion' => '1.4',
      'version' => 1,
      'serialNumber' => "urn:uuid:#{uuid}"
    }
  end

  subject(:parse!) { described_class.new.parse!(raw_report_data, report) }

  before do
    allow_next_instance_of(Gitlab::Ci::Parsers::Sbom::Validators::CyclonedxSchemaValidator) do |validator|
      allow(validator).to receive(:valid?).and_return(report_valid?)
      allow(validator).to receive(:errors).and_return(validator_errors)
    end

    allow(SecureRandom).to receive(:uuid).and_return(uuid)
  end

  context 'when report is invalid' do
    context 'when report JSON is invalid' do
      let(:raw_report_data) { '{ ' }

      it 'handles errors and adds them to the report' do
        expect(report).to receive(:add_error).with(a_string_including("Report JSON is invalid:"))

        expect { parse! }.not_to raise_error
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
  end

  context 'when cyclonedx report has no components' do
    it 'skips component processing' do
      expect(report).not_to receive(:add_component)

      parse!
    end
  end

  context 'when report has dependency_scanning components' do
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
                          .with(an_object_having_attributes(name: "minimal-component", version: nil,
                            component_type: "library"))

      parse!
    end

    context 'when component is trivy type' do
      let(:parsed_properties) do
        {
          'PkgID' => 'activesupport@5.1.4',
          'PkgType' => 'gem'
        }
      end

      let(:components) do
        [
          {
            # Trivy component
            "bom-ref" => "0eda252d-d8a4-4250-b816-b6314f029063",
            "type" => "library",
            "name" => "analyzer",
            "purl" => "pkg:gem/activesupport@5.1.4",
            "properties" => [
              {
                "name" => "aquasecurity:trivy:PkgID",
                "value" => "activesupport@5.1.4"
              },
              {
                "name" => "aquasecurity:trivy:PkgType",
                "value" => "gem"
              }
            ]
          }
        ]
      end

      it 'adds each component, ignoring unused attributes' do
        expect(report).to receive(:add_component)
          .with(
            an_object_having_attributes(
              component_type: "library",
              properties: an_object_having_attributes(
                data: parsed_properties
              ),
              purl: an_object_having_attributes(
                type: "gem"
              )
            )
          )
        parse!
      end
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

    context 'when a component has license information' do
      let(:license_id) { "Apache-2.0" }
      let(:license_url) { "https://www.apache.org/licenses/LICENSE-2.0.txt" }
      let(:components) do
        [
          {
            "type" => "library",
            "group" => "com.acme",
            "name" => "tomcat-catalina",
            "version" => "9.0.14",
            "licenses" => [
              {
                "license" => {
                  "id" => license_id,
                  "url" => license_url
                }
              }
            ]
          }
        ]
      end

      it 'adds component with license information' do
        expected_license = an_object_having_attributes(
          spdx_identifier: license_id,
          name: nil,
          url: license_url)

        expect(report).to receive(:add_component)
                            .with(an_object_having_attributes(licenses: [expected_license]))

        parse!
      end
    end
  end

  context 'when report has container_scanning components' do
    let(:report_data) { base_report_data.merge({ 'components' => components }) }

    let(:parsed_properties) do
      {
        'SrcName' => 'alpine-baselayout'
      }
    end

    let(:components) do
      [
        {
          "name" => "alpine",
          "version" => "3.4.3-r1",
          "purl" => "pkg:apk/alpine/alpine@3.4.3-r1?arch=x86_64&distro=3.18.4",
          "type" => "library",
          "bom-ref" => "pkg:apk/alpine/alpine@3.4.3-r1?arch=x86_64&distro=3.18.4"
        },
        {
          "name" => "alpine-baselayout-data",
          "version" => "3.4.3-r1",
          "purl" => "pkg:apk/alpine/alpine-baselayout-data@3.4.3-r1?arch=x86_64&distro=3.18.4",
          "type" => "library",
          "bom-ref" => "pkg:apk/alpine/alpine-baselayout-data@3.4.3-r1?arch=x86_64&distro=3.18.4",
          "properties" => [
            {
              "name" => "aquasecurity:trivy:SrcName",
              "value" => "alpine-baselayout"
            }
          ]
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
            name: "alpine",
            version: "3.4.3-r1",
            component_type: "library",
            purl: an_object_having_attributes(type: "apk"),
            properties: nil,
            source_package_name: 'alpine'
          )
        )
      expect(report).to receive(:add_component)
        .with(
          an_object_having_attributes(
            name: "alpine-baselayout-data",
            version: "3.4.3-r1",
            component_type: "library",
            purl: an_object_having_attributes(type: "apk"),
            properties: an_object_having_attributes(
              data: parsed_properties
            ),
            source_package_name: 'alpine-baselayout'
          )
        )

      parse!
    end
  end

  context 'when report has metadata tools, author and properties' do
    let(:report_data) { base_report_data.merge(metadata) }

    let(:tools) do
      [
        { name: 'Gemnasium', vendor: 'vendor-1', version: '2.34.0' },
        { name: 'Gemnasium', vendor: 'vendor-2', version: '2.34.0' }
      ]
    end

    let(:authors) do
      [
        { name: 'author-1', email: 'support@gitlab.com' },
        { name: 'author-2', email: 'support@gitlab.com' }
      ]
    end

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

    context 'when metadata attributes are present' do
      let(:metadata) do
        {
          'metadata' => {
            'tools' => tools,
            'authors' => authors,
            'properties' => properties
          }
        }
      end

      it 'passes them to the report' do
        expect(properties_parser).to receive(:parse_source).with(properties)

        parse!

        expect(report.metadata).to have_attributes(
          tools: tools.map(&:with_indifferent_access),
          authors: authors.map(&:with_indifferent_access),
          properties: properties.map(&:with_indifferent_access)
        )
      end
    end

    context 'when metadata attributes are not present' do
      let(:metadata) { { 'metadata' => {} } }

      it 'passes them to the report' do
        expect(properties_parser).to receive(:parse_source).with(nil)

        parse!

        expect(report.metadata).to have_attributes(
          tools: [],
          authors: [],
          properties: []
        )
      end
    end
  end

  context 'when cyclonedx report has no dependencies' do
    it 'skips component processing' do
      expect(report).not_to receive(:add_dependency)

      parse!
    end
  end

  context 'when report has dependencies' do
    let(:report_data) { base_report_data.merge({ 'dependencies' => [{ ref: 'ref', dependsOn: ['dependency_ref'] }] }) }

    it 'passes dependencies to report' do
      expect(report).to receive(:add_dependency).with('ref', 'dependency_ref')

      parse!
    end
  end

  context 'when report has components with reachability' do
    let(:report_data) { base_report_data.merge({ 'components' => components }) }

    let(:parsed_properties) do
      {
        'reachability' => 'in_use'
      }
    end

    let(:components) do
      [
        {
          "name" => "GitPython",
          "version" => "3.1.44",
          "purl" => "pkg:pypi/GitPython@3.1.44",
          "type" => "library",
          "bom-ref" => "pkg:pypi/GitPython@3.1.44",
          "properties" => [
            {
              "name" => "gitlab:dependency_scanning_component:reachability",
              "value" => "in_use"
            }
          ]
        }
      ]
    end

    before do
      allow(report).to receive(:add_component)
    end

    it 'adds component with the reachability property' do
      expect(report).to receive(:add_component)
        .with(
          an_object_having_attributes(
            name: "gitpython",
            version: "3.1.44",
            component_type: "library",
            purl: an_object_having_attributes(type: "pypi"),
            properties: an_object_having_attributes(
              data: parsed_properties
            )
          )
        )
      parse!
    end
  end
end
