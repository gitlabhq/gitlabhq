# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::CheckManifestCoherenceService, :aggregate_failures, feature_category: :package_registry do
  let_it_be(:package) { build(:npm_package) }

  let(:tar_header) { Gem::Package::TarHeader.new(name: 'json', size: package_json.size, mode: 0o644, prefix: '') }
  let(:package_json_entry) { Gem::Package::TarReader::Entry.new(tar_header, StringIO.new(package_json)) }
  let(:service) { described_class.new(package, package_json_entry) }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject(:execute_service) { service.execute }

    let(:package_name) { package.name }
    let(:package_version) { package.version }

    where(:name, :version, :coherent) do
      ref(:package_name) | ref(:package_version) | true
      'foo'              | ref(:package_version) | false
      ref(:package_name) | '5.0.3'               | false
      'foo'              | '5.0.3'               | false
    end

    with_them do
      let(:package_json) do
        {
          name: name,
          version: version
        }.to_json
      end

      if params[:coherent]
        it { is_expected.to be_success }
      else
        it 'raises a mismatch error' do
          expect { execute_service }
            .to raise_error(described_class::MismatchError, 'Package manifest is not coherent')
        end
      end
    end

    %i[name version].each do |field|
      context "with field #{field} present in sub key" do
        let(:package_json) do
          {
            name: package.name,
            version: package.version,
            subkey: { field => 'test' }
          }.to_json
        end

        it { is_expected.to be_success }
      end
    end

    context 'with auto corrected version' do
      where(:version_in_payload, :version_in_tarball, :coherent, :error_message) do
        '5.0.3'        | '5.0.3'             | true  | nil
        '5.0.3'        | '5.0.4'             | false | described_class::MANIFEST_NOT_COHERENT_ERROR
        '5.0.3'        | 'v5.0.3'            | true  | nil
        '5.0.3'        | '5.0.3+build'       | true  | nil
        '5.0.3'        | 'v5.0.3+build'      | true  | nil
        '5.0.3-test'   | '5.0.3-test+build'  | true  | nil
        '5.0.3-test'   | 'v5.0.3-test+build' | true  | nil
        '5.0.3-test'   | 'v5.0.3+build-test' | false | described_class::MANIFEST_NOT_COHERENT_ERROR
        '5.0.3'        | 'v5.0.3+build-test' | true  | nil
        '5.0.3'        | '=5.0.3'            | true  | nil
        '5.1.3'        | '05.01.03'          | true  | nil
        '5.1.3-beta.1' | '5.1.3-beta.01'     | true  | nil
        '5.0.3'        | '=5.0.3'            | true  | nil
        '5.0.3-beta'   | '5.0.3beta'         | false | described_class::VERSION_NOT_COMPLIANT_ERROR
      end

      with_them do
        let(:package_json) do
          {
            name: package.name,
            version: version_in_tarball
          }.to_json
        end

        before do
          package.version = version_in_payload
        end

        if params[:coherent]
          it { is_expected.to be_success }
        else
          it 'raises a mismatch error' do
            expect { execute_service }
              .to raise_error(described_class::MismatchError, error_message)
          end
        end
      end
    end
  end
end
