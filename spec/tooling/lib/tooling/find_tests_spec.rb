# frozen_string_literal: true

require 'tempfile'
require_relative '../../../../tooling/lib/tooling/find_tests'
require_relative '../../../support/helpers/stub_env'

RSpec.describe Tooling::FindTests, feature_category: :tooling do
  include StubENV

  attr_accessor :changes_file, :matching_tests_paths

  let(:instance)                     { described_class.new(changes_file, matching_tests_paths) }
  let(:mock_test_file_finder)        { instance_double(TestFileFinder::FileFinder) }
  let(:new_matching_tests)           { ["new_matching_spec.rb"] }
  let(:changes_file_content)         { "changed_file1 changed_file2" }
  let(:matching_tests_paths_content) { "previously_matching_spec.rb" }

  around do |example|
    self.changes_file         = Tempfile.new('changes')
    self.matching_tests_paths = Tempfile.new('matching_tests')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      example.run
    ensure
      changes_file.close
      matching_tests_paths.close
      changes_file.unlink
      matching_tests_paths.unlink
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
    File.write(changes_file, changes_file_content)
    File.write(matching_tests_paths, matching_tests_paths_content)
  end

  describe '#execute' do
    subject { instance.execute }

    context 'when the matching_tests_paths file does not exist' do
      before do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:write).with(matching_tests_paths, any_args)
      end

      it 'creates an empty file' do
        expect(File).to receive(:write).with(matching_tests_paths, '')

        subject
      end
    end

    context 'when the matching_tests_paths file already exists' do
      it 'does not create an empty file' do
        expect(File).not_to receive(:write).with(matching_tests_paths, '')

        subject
      end
    end

    it 'does not modify the content of the input file' do
      expect { subject }.not_to change { File.read(changes_file) }
    end

    it 'does not overwrite the output file' do
      expect { subject }.to change { File.read(matching_tests_paths) }
                        .from(matching_tests_paths_content)
                        .to("#{matching_tests_paths_content} #{new_matching_tests.uniq.join(' ')}")
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
          .with('crystalball-test/mapping.json')

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

        expect(File.read(matching_tests_paths).split(' ')).to match_array(
          matching_tests_paths_content.split(' ') + new_matching_tests.uniq
        )
      end
    end
  end
end
