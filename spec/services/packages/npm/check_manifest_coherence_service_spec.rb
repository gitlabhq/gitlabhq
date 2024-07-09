# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::CheckManifestCoherenceService, :aggregate_failures, feature_category: :package_registry do
  let_it_be(:package) { build(:npm_package) }
  let_it_be(:package_metadata) { build(:npm_metadatum, package: package) }
  let(:tar_header) { Gem::Package::TarHeader.new(name: 'json', size: package_json.size, mode: 0o644, prefix: '') }
  let(:package_json_entry) { Gem::Package::TarReader::Entry.new(tar_header, StringIO.new(package_json)) }
  let(:service) { described_class.new(package, package_json_entry) }

  subject(:execute_service) { service.execute }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

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

    context 'when the package metadata is missing' do
      let(:package_json) { { name: package_name, version: package_version, scripts: {} }.to_json }

      before do
        package.npm_metadatum = nil
      end

      it { is_expected.to be_success }
    end
  end

  describe 'SajHandler' do
    let(:handler) { described_class::SajHandler.new }

    describe 'parsing a json document' do
      let(:json) { { name: 'test', version: '1.2.3', scripts: { test: 'echo "test"' } }.to_json }

      subject(:parse) { ::Oj.saj_parse(handler, json) }

      it 'extracts the fields' do
        expect { parse }.to raise_error(described_class::SajHandler::ParsingDoneError)

        expect(handler.name).to eq('test')
        expect(handler.version).to eq('1.2.3')
        expect(handler.scripts).to eq('test' => 'echo "test"')
      end

      context 'with a different fields order' do
        let(:json) { { scripts: { test: 'echo "test"' }, name: 'test', version: '1.2.3' }.to_json }

        it 'extracts the fields' do
          expect { parse }.to raise_error(described_class::SajHandler::ParsingDoneError)

          expect(handler.name).to eq('test')
          expect(handler.version).to eq('1.2.3')
          expect(handler.scripts).to eq('test' => 'echo "test"')
        end
      end

      context 'with no scripts field' do
        let(:json) { { name: 'test', version: '1.2.3' }.to_json }

        it 'extracts the name and version fields' do
          expect { parse }.not_to raise_error

          expect(handler.name).to eq('test')
          expect(handler.version).to eq('1.2.3')
          expect(handler.scripts).to eq({})
        end
      end

      context 'with very large fields' do
        let(:json) do
          {
            name: 'test',
            version: '1.2.3',
            scripts: { test: 'echo "test"' },
            extra: 'test' * 10000,
            another_hash: { large_field: 'aaaa' * 10000 }
          }.to_json
        end

        it 'avoids extract large fields' do
          expect(handler).to receive(:hash_start).twice.and_call_original
          expect(handler).to receive(:hash_end).once.and_call_original
          expect(handler).to receive(:add_value).exactly(3).times.and_call_original

          expect { parse }.to raise_error(described_class::SajHandler::ParsingDoneError)

          expect(handler.name).to eq('test')
          expect(handler.version).to eq('1.2.3')
          expect(handler.scripts).to eq('test' => 'echo "test"')
        end
      end
    end
  end
end
