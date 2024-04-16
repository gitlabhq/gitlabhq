# frozen_string_literal: true

require 'tempfile'
require_relative '../../../../tooling/lib/tooling/find_tests'
require 'gitlab/rspec/all'

RSpec.describe Tooling::FindTests, feature_category: :tooling do
  include StubENV

  attr_accessor :changed_files_file, :predictive_tests_file

  let(:instance)                     { described_class.new(changed_files_pathname, predictive_tests_pathname) }
  let(:mock_test_file_finder)        { instance_double(TestFileFinder::FileFinder) }
  let(:new_matching_tests)           { ["new_matching_spec.rb"] }
  let(:changed_files_pathname)       { changed_files_file.path }
  let(:predictive_tests_pathname)    { predictive_tests_file.path }
  let(:changed_files_content)        { "changed_file1 changed_file2" }
  let(:predictive_tests_content)     { "previously_matching_spec.rb" }

  around do |example|
    self.changed_files_file    = Tempfile.new('changed_files_file')
    self.predictive_tests_file = Tempfile.new('predictive_tests_file')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      example.run
    ensure
      changed_files_file.close
      predictive_tests_file.close
      changed_files_file.unlink
      predictive_tests_file.unlink
    end
  end

  before do
    allow(mock_test_file_finder).to receive(:use)
    allow(mock_test_file_finder).to receive(:test_files).and_return(new_matching_tests)
    allow(TestFileFinder::FileFinder).to receive(:new).and_return(mock_test_file_finder)

    stub_env(
      'RSPEC_TESTS_MAPPING_ENABLED' => nil,
      'RSPEC_TESTS_MAPPING_PATH' => '/tmp/does-not-exist.out'
    )

    # We write into the temp files initially, to later check how the code modified those files
    File.write(changed_files_pathname, changed_files_content)
    File.write(predictive_tests_pathname, predictive_tests_content)
  end

  describe '#execute' do
    subject { instance.execute }

    context 'when the predictive_tests_pathname file does not exist' do
      let(:instance) { described_class.new(non_existing_output_pathname, predictive_tests_pathname) }
      let(:non_existing_output_pathname) { 'tmp/another_file.out' }

      around do |example|
        example.run
      ensure
        FileUtils.rm_rf(non_existing_output_pathname)
      end

      it 'creates the file' do
        expect { subject }.to change { File.exist?(non_existing_output_pathname) }.from(false).to(true)
      end
    end

    context 'when the predictive_tests_pathname file already exists' do
      it 'does not create an empty file' do
        expect(File).not_to receive(:write).with(predictive_tests_pathname, '')

        subject
      end
    end

    it 'does not modify the content of the input file' do
      expect { subject }.not_to change { File.read(changed_files_pathname) }
    end

    it 'does not overwrite the output file' do
      expect { subject }.to change { File.read(predictive_tests_pathname) }
                        .from(predictive_tests_content)
                        .to("#{predictive_tests_content} #{new_matching_tests.uniq.join(' ')}")
    end

    it 'loads the tests.yml file with a pattern matching mapping' do
      expect(TestFileFinder::MappingStrategies::PatternMatching).to receive(:load).with('tests.yml')

      subject
    end

    context 'when RSPEC_TESTS_MAPPING_ENABLED env variable is set' do
      before do
        stub_env(
          'RSPEC_TESTS_MAPPING_ENABLED' => 'true',
          'RSPEC_TESTS_MAPPING_PATH' => 'crystalball-test/mapping.json'
        )
      end

      it 'loads the direct matching pattern file' do
        expect(TestFileFinder::MappingStrategies::DirectMatching)
          .to receive(:load_json)
          .with('crystalball-test/mapping.json', limit_min: 14, limit_percentage: 50)

        subject
      end
    end

    context 'when RSPEC_TESTS_MAPPING_ENABLED env variable is not set' do
      let(:rspec_tests_mapping_enabled) { '' }

      before do
        stub_env(
          'RSPEC_TESTS_MAPPING_ENABLED' => rspec_tests_mapping_enabled,
          'RSPEC_TESTS_MAPPING_PATH' => rspec_tests_mapping_path
        )
      end

      context 'when RSPEC_TESTS_MAPPING_PATH is set' do
        let(:rspec_tests_mapping_path) { 'crystalball-test/mapping.json' }

        it 'does not load the direct matching pattern file' do
          expect(TestFileFinder::MappingStrategies::DirectMatching).not_to receive(:load_json)

          subject
        end
      end

      context 'when RSPEC_TESTS_MAPPING_PATH is not set' do
        let(:rspec_tests_mapping_path) { nil }

        it 'does not load the direct matching pattern file' do
          expect(TestFileFinder::MappingStrategies::DirectMatching).not_to receive(:load_json)

          subject
        end
      end
    end

    context 'when the same spec is matching multiple times' do
      let(:new_matching_tests) do
        [
          "new_matching_spec.rb",
          "duplicate_spec.rb",
          "duplicate_spec.rb"
        ]
      end

      it 'writes uniquely matching specs to the output' do
        subject

        expect(File.read(predictive_tests_pathname).split(' ')).to match_array(
          predictive_tests_content.split(' ') + new_matching_tests.uniq
        )
      end
    end
  end
end
