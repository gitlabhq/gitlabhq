# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::CheckManifestCoherenceService, :aggregate_failures, feature_category: :package_registry do
  let_it_be(:package) { build(:npm_package) }
  let_it_be(:package_metadata) { build(:npm_metadatum, package: package) }
  let(:tar_header) { Gem::Package::TarHeader.new(name: 'json', size: package_json.size, mode: 0o644, prefix: '') }
  let(:package_json_entry) { Gem::Package::TarReader::Entry.new(tar_header, StringIO.new(package_json)) }
  let(:service) { described_class.new(package, package_json_entry) }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject(:execute_service) { service.execute }

    let(:package_name) { package.name }
    let(:package_version) { package.version }
    let(:package_scripts) { package_metadata.package_json_scripts }

    where(:name, :version, :scripts, :coherent) do
      ref(:package_name) | ref(:package_version) | ref(:package_scripts)        | true
      'foo'              | ref(:package_version) | ref(:package_scripts)        | false
      ref(:package_name) | '5.0.3'               | ref(:package_scripts)        | false
      ref(:package_name) | ref(:package_version) | { test: 'different script' } | false
      'foo'              | '5.0.3'               | { test: 'different script' } | false
    end

    with_them do
      let(:package_json) do
        {
          name: name,
          version: version,
          scripts: scripts
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

    %i[name version scripts].each do |field|
      context "with field #{field} present in sub key" do
        let(:package_json) do
          {
            name: package.name,
            version: package.version,
            subkey: { field => 'test' },
            scripts: package_metadata.package_json_scripts
          }.to_json
        end

        it { is_expected.to be_success }
      end
    end

    context 'when the package metadata is missing' do
      let(:package_json) { { name: package_name, version: package_version, scripts: {} }.to_json }

      before do
        package.npm_metadatum = nil
      end

      it { is_expected.to be_success }
    end
  end
end
