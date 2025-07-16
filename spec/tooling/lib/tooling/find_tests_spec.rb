# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/find_tests'
require 'fast_spec_helper'

RSpec.describe Tooling::FindTests, feature_category: :tooling do
  let(:instance) do
    described_class.new(
      changed_files,
      mappings_file: mappings_file,
      mappings_limit_percentage: 50
    )
  end

  let(:mock_test_file_finder) { instance_double(TestFileFinder::FileFinder) }
  let(:new_matching_tests) { ["new_matching_spec.rb"] }
  let(:changed_files) { %w[changed_file1 changed_file2] }
  let(:mappings_file) { nil }

  before do
    allow(mock_test_file_finder).to receive(:use)
    allow(mock_test_file_finder).to receive(:test_files).and_return(new_matching_tests)
    allow(TestFileFinder::FileFinder).to receive(:new).and_return(mock_test_file_finder)
  end

  describe '#execute' do
    subject { instance.execute }

    it 'returns matched files list' do
      expect(subject).to match_array(new_matching_tests.uniq)
    end

    it 'loads the tests.yml file with a pattern matching mapping' do
      expect(TestFileFinder::MappingStrategies::PatternMatching).to receive(:load).with('tests.yml')

      subject
    end

    context 'when test mapping file is set' do
      let(:mappings_file) { 'crystalball-test/mapping.json' }

      it 'loads the direct matching pattern file' do
        expect(TestFileFinder::MappingStrategies::DirectMatching)
          .to receive(:load_json)
          .with(mappings_file, limit_min: 14, limit_percentage: 50)

        subject
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

      it 'return only unique specs' do
        expect(subject).to match_array(new_matching_tests.uniq)
      end
    end
  end
end
