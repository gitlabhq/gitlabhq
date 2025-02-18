# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::Component, feature_category: :dependency_management do
  describe "#parse" do
    subject(:component) { described_class.new(data).parse }

    context "with dependency scanning component" do
      let(:data) do
        {
          "name" => "activesupport",
          "version" => "5.1.4",
          "purl" => "pkg:gem/activesupport@5.1.4",
          "type" => "library",
          "bom-ref" => "pkg:gem/activesupport@5.1.4"
        }
      end

      it "sets the expected values" do
        is_expected.to be_kind_of(::Gitlab::Ci::Reports::Sbom::Component)

        expect(component.component_type).to eq("library")
        expect(component.name).to eq("activesupport")
        expect(component.version).to eq("5.1.4")
        expect(component.purl).to be_kind_of(::Sbom::PackageUrl)
        expect(component.purl.name).to eq("activesupport")
        expect(component.properties).to be_nil
        expect(component.source_package_name).to be_nil
        expect(component.ref).to eq("pkg:gem/activesupport@5.1.4")
      end

      context "with license information" do
        let(:license_name) { "card-verifier" }
        let(:license_info) { { "licenses" => ["license" => { "name" => license_name }] } }

        before do
          data.merge!(license_info)
        end

        it "sets the license information" do
          is_expected.to be_kind_of(::Gitlab::Ci::Reports::Sbom::Component)
          expect(component.licenses.count).to eq(1)
          expect(component.licenses.first.name).to eq(license_name)
        end

        context "when the license is defined by an expression" do
          let(:license_info) do
            { "licenses" => [{ "expression" => "EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0" }] }
          end

          it "ignores the license" do
            expect(component.licenses).to be_empty
          end
        end
      end
    end

    context "with container scanning component" do
      let(:property_name) { 'aquasecurity:trivy:PkgType' }
      let(:property_value) { 'alpine' }
      let(:purl) { "pkg:apk/alpine/alpine-baselayout-data@3.4.3-r1?arch=x86_64&distro=3.18.4" }
      let(:data) do
        {
          "name" => "alpine-baselayout-data",
          "version" => "3.4.3-r1",
          "purl" => purl,
          "type" => "library",
          "bom-ref" => purl,
          "properties" => [
            {
              "name" => property_name,
              "value" => property_value
            }
          ]
        }
      end

      context "with an aquasecurity:trivy:SrcName property" do
        let(:property_name) { "aquasecurity:trivy:SrcName" }
        let(:property_value) { "alpine-baselayout" }

        it "sets properties field with parsed data" do
          property_data = component.properties.data

          expect(property_data).to match({ "SrcName" => "alpine-baselayout" })
        end

        it "sets the source_package_name from the aquasecurity:trivy:SrcName property" do
          expect(component.source_package_name).to eq(property_value)
        end
      end

      context "without an aquasecurity:trivy:SrcName property" do
        it "sets properties field with parsed data" do
          property_data = component.properties.data

          expect(property_data).to match({ "PkgType" => "alpine" })
        end

        it "sets the source_package_name from the component name" do
          expect(component.source_package_name).to eq("alpine-baselayout-data")
        end
      end

      context "without properties" do
        it "sets the source_package_name from the component name" do
          data.delete('properties')
          expect(component.source_package_name).to eq("alpine-baselayout-data")
        end
      end

      context "with corrupted purl" do
        let(:purl) { "unknown:apk/alpine/alpine-baselayout-data@3.4.3-r1?arch=x86_64&distro=3.18.4" }

        it "raises an error" do
          expect { component }.to raise_error(::Sbom::PackageUrl::InvalidPackageUrl)
        end
      end
    end
  end
end
