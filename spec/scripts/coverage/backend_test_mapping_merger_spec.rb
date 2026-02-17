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
  let(:described_mapping_file) { File.join(crystalball_dir, 'packed-mapping.json.gz') }
  let(:coverage_mapping_file) { File.join(crystalball_dir, 'packed-mapping-alt.json.gz') }
  let(:merged_mapping_path) { File.join(crystalball_dir, 'merged-mapping.json.gz') }
  let(:e2e_mapping) { { 'qa/specs/login_spec.rb' => ['app/models/user.rb'] } }
  let(:described_class_mapping) { { 'app/models/user.rb' => { 'spec' => { 'models' => { 'user_spec.rb' => 1 } } } } }
  let(:coverage_mapping) do
    {
      'lib/tasks/gitlab/db/detach_partition.rake' => {
        'spec' => { 'tasks' => { 'gitlab' => { 'db' => { 'detach_partition_rake_spec.rb' => 1 } } } }
      }
    }
  end

  before do
    allow(merger).to receive(:puts)
    allow(merger).to receive(:warn)

    FileUtils.mkdir_p(e2e_dir)
    FileUtils.mkdir_p(crystalball_dir)

    stub_const('BackendTestMappingMerger::E2E_MAPPING_ARTIFACT_GLOB', File.join(e2e_dir, '*.json'))
    stub_const('BackendTestMappingMerger::CRYSTALBALL_DESCRIBED_MAPPING_PATH', described_mapping_file)
    stub_const('BackendTestMappingMerger::CRYSTALBALL_COVERAGE_MAPPING_PATH', coverage_mapping_file)
    stub_const('BackendTestMappingMerger::MERGED_MAPPING_PATH', merged_mapping_path)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_e2e_mapping(mapping, filename: 'test-code-paths-mapping-123.json')
    File.write(File.join(e2e_dir, filename), mapping.to_json)
  end

  def create_described_class_mapping(mapping)
    Zlib::GzipWriter.open(described_mapping_file) { |gz| gz.write(mapping.to_json) }
  end

  def create_coverage_mapping(mapping)
    Zlib::GzipWriter.open(coverage_mapping_file) { |gz| gz.write(mapping.to_json) }
  end

  def read_merged_mapping
    content = Zlib::GzipReader.open(merged_mapping_path, &:read)
    Gitlab::Json.parse(content)
  end

  describe '#run' do
    context 'when all mapping sources exist' do
      before do
        create_e2e_mapping(e2e_mapping)
        create_described_class_mapping(described_class_mapping)
        create_coverage_mapping(coverage_mapping)
      end

      it 'merges mappings and returns true' do
        result = merger.run

        expect(result).to be true
        expect(File.exist?(merged_mapping_path)).to be true
      end

      it 'combines tests from all mapping sources' do
        merger.run

        loaded = read_merged_mapping
        # From described_class mapping
        expect(loaded['app/models/user.rb']['spec']['models']['user_spec.rb']).to eq(1)
        # From e2e mapping
        expect(loaded['app/models/user.rb']['qa']['specs']['login_spec.rb']).to eq(1)
        # From coverage mapping (tests .rake file mapping)
        rake_file_mapping = loaded['lib/tasks/gitlab/db/detach_partition.rake']
        expect(rake_file_mapping['spec']['tasks']['gitlab']['db']['detach_partition_rake_spec.rb']).to eq(1)
      end
    end

    context 'when only coverage mapping exists' do
      before do
        create_coverage_mapping(coverage_mapping)
      end

      it 'returns true and includes .rake file mappings' do
        result = merger.run

        expect(result).to be true
        expect(File.exist?(merged_mapping_path)).to be true

        loaded = read_merged_mapping
        expect(loaded['lib/tasks/gitlab/db/detach_partition.rake']).to be_present
      end
    end

    context 'when E2E mappings are missing but Crystalball exists' do
      before do
        create_described_class_mapping(described_class_mapping)
      end

      it 'returns true and uses Crystalball mapping only' do
        result = merger.run

        expect(result).to be true
        expect(File.exist?(merged_mapping_path)).to be true
        expect(merger).to have_received(:puts).with('No E2E mappings found, will use Crystalball mapping only')
      end
    end

    context 'when Crystalball mappings are missing but E2E exists' do
      before do
        create_e2e_mapping(e2e_mapping)
        stub_const('BackendTestMappingMerger::CRYSTALBALL_DESCRIBED_MAPPING_PATH', 'nonexistent/path.json.gz')
        stub_const('BackendTestMappingMerger::CRYSTALBALL_COVERAGE_MAPPING_PATH', 'nonexistent/alt.json.gz')
      end

      it 'returns true and uses E2E mapping only' do
        result = merger.run

        expect(result).to be true
        expect(File.exist?(merged_mapping_path)).to be true
        expect(merger).to have_received(:puts).with(/described_class mapping not found/)
        expect(merger).to have_received(:puts).with(/coverage mapping not found/)
      end
    end

    context 'when all mappings are missing' do
      before do
        stub_const('BackendTestMappingMerger::CRYSTALBALL_DESCRIBED_MAPPING_PATH', 'nonexistent/path.json.gz')
        stub_const('BackendTestMappingMerger::CRYSTALBALL_COVERAGE_MAPPING_PATH', 'nonexistent/alt.json.gz')
      end

      it 'returns false' do
        result = merger.run

        expect(result).to be false
        expect(merger).to have_received(:warn)
          .with('ERROR: All mappings are missing, cannot produce merged mapping')
      end
    end

    context 'when E2E mapping file has invalid JSON' do
      before do
        create_e2e_mapping(e2e_mapping, filename: 'test-code-paths-mapping-1.json')
        File.write(File.join(e2e_dir, 'test-code-paths-mapping-2.json'), 'not valid json')
        create_described_class_mapping(described_class_mapping)
      end

      it 'skips the invalid file and continues' do
        result = merger.run

        expect(result).to be true
        expect(merger).to have_received(:warn).with(/Failed to parse/)
      end
    end

    context 'when E2E mapping contains absolute paths' do
      let(:e2e_mapping_with_absolute_paths) do
        {
          'qa/specs/login_spec.rb' => [
            '/builds/gitlab-org/gitlab/app/models/user.rb',
            '/home/gdk/gitlab-development-kit/gitlab/lib/api/api.rb'
          ]
        }
      end

      before do
        create_e2e_mapping(e2e_mapping_with_absolute_paths)
        create_described_class_mapping(described_class_mapping)
      end

      it 'normalizes absolute paths to relative paths' do
        merger.run

        loaded = read_merged_mapping
        # Should have normalized paths, not absolute paths
        expect(loaded['app/models/user.rb']).to be_present
        expect(loaded['lib/api/api.rb']).to be_present
        # Should not have absolute paths
        expect(loaded['/builds/gitlab-org/gitlab/app/models/user.rb']).to be_nil
        expect(loaded['/home/gdk/gitlab-development-kit/gitlab/lib/api/api.rb']).to be_nil
      end
    end
  end
end
