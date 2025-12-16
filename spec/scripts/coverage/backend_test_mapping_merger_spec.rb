# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'zlib'
require 'json'
require_relative '../../../scripts/coverage/merge_e2e_backend_test_mapping'

RSpec.describe BackendTestMappingMerger, feature_category: :tooling do
  let(:merger) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:e2e_dir) { File.join(temp_dir, 'e2e-test-mapping') }
  let(:crystalball_dir) { File.join(temp_dir, 'crystalball') }
  let(:crystalball_file) { File.join(crystalball_dir, 'packed-mapping.json.gz') }
  let(:merged_mapping_path) { File.join(crystalball_dir, 'merged-mapping.json.gz') }
  let(:e2e_mapping) { { 'qa/specs/login_spec.rb' => ['app/models/user.rb'] } }
  let(:crystalball_mapping) { { 'app/models/user.rb' => { 'spec' => { 'models' => { 'user_spec.rb' => 1 } } } } }

  before do
    allow(merger).to receive(:puts)
    allow(merger).to receive(:warn)

    FileUtils.mkdir_p(e2e_dir)
    FileUtils.mkdir_p(crystalball_dir)

    stub_const('BackendTestMappingMerger::E2E_MAPPING_ARTIFACT_GLOB', File.join(e2e_dir, '*.json'))
    stub_const('BackendTestMappingMerger::CRYSTALBALL_MAPPING_PATH', crystalball_file)
    stub_const('BackendTestMappingMerger::MERGED_MAPPING_PATH', merged_mapping_path)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_e2e_mapping(mapping, filename: 'test-code-paths-mapping-123.json')
    File.write(File.join(e2e_dir, filename), mapping.to_json)
  end

  def create_crystalball_mapping(mapping)
    Zlib::GzipWriter.open(crystalball_file) { |gz| gz.write(mapping.to_json) }
  end

  def read_merged_mapping
    content = Zlib::GzipReader.open(merged_mapping_path, &:read)
    Gitlab::Json.parse(content)
  end

  describe '#run' do
    context 'when both E2E and Crystalball mappings exist' do
      before do
        create_e2e_mapping(e2e_mapping)
        create_crystalball_mapping(crystalball_mapping)
      end

      it 'merges mappings and returns true' do
        result = merger.run

        expect(result).to be true
        expect(File.exist?(merged_mapping_path)).to be true
      end

      it 'combines tests from both mappings for the same source file' do
        merger.run

        loaded = read_merged_mapping
        expect(loaded['app/models/user.rb']['spec']['models']['user_spec.rb']).to eq(1)
        expect(loaded['app/models/user.rb']['qa']['specs']['login_spec.rb']).to eq(1)
      end
    end

    context 'when E2E mappings are missing' do
      it 'returns false' do
        result = merger.run

        expect(result).to be false
        expect(merger).to have_received(:warn).with('ERROR: No E2E mappings found')
      end
    end

    context 'when Crystalball mapping is missing' do
      before do
        create_e2e_mapping(e2e_mapping)
        stub_const('BackendTestMappingMerger::CRYSTALBALL_MAPPING_PATH', 'nonexistent/path.json.gz')
      end

      it 'returns false' do
        result = merger.run

        expect(result).to be false
        expect(merger).to have_received(:warn).with(/Crystalball mapping not found/)
      end
    end

    context 'when E2E mapping file has invalid JSON' do
      let(:other_crystalball_mapping) do
        { 'app/services/auth.rb' => { 'spec' => { 'services' => { 'auth_spec.rb' => 1 } } } }
      end

      before do
        create_e2e_mapping(e2e_mapping, filename: 'test-code-paths-mapping-1.json')
        File.write(File.join(e2e_dir, 'test-code-paths-mapping-2.json'), 'not valid json')
        create_crystalball_mapping(other_crystalball_mapping)
      end

      it 'skips the invalid file and continues' do
        result = merger.run

        expect(result).to be true
        expect(merger).to have_received(:warn).with(/Failed to parse/)
      end
    end
  end
end
