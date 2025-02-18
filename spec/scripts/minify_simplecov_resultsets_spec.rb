# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/minify-simplecov-resultsets'

RSpec.describe MinifySimplecovResultsets, feature_category: :tooling do
  let(:root_dir) { described_class::ROOT_DIR }
  let(:resultset_path) { root_dir.join('coverage', 'rspec-job-1', '.resultset.json') }

  subject(:minifier) { described_class.new }

  before do
    allow(Dir).to receive(:glob).with(root_dir.join('coverage', '*', '.resultset.json')) { [resultset_path.to_s] }
    allow(File).to receive(:write)
    stub_file_read(resultset_path, content: original_content)
    allow(minifier).to receive(:puts)
  end

  describe '#minify' do
    let(:original_content) do
      <<~JSON
        {
          "rspec-job-1": {
            "coverage": {
              "file1.rb": [1, 2, 3, null],
              "file2.rb": [4, 5, 6, null]
            },
            "timestamp": 1234567890
          }
        }
      JSON
    end

    let(:minified_content) { original_content.gsub(/[\s\n]+/, '') }

    it 'minifies the resultset JSON file' do
      expect(File).to receive(:write).with(resultset_path, minified_content)
      minifier.minify
      expect(minified_content.size).to be < original_content.size
    end

    it 'outputs the minification result' do
      expect(minifier).to receive(:puts).with("Minified coverage/rspec-job-1/.resultset.json: 0KB -> 0KB (-33%)")
      minifier.minify
    end

    it 'retains the same semantic value' do
      # rubocop:disable Gitlab/Json -- We also use JSON in scripts
      expect(JSON.parse(original_content)).to eq(JSON.parse(minified_content))
      # rubocop:enable Gitlab/Json
    end

    it 'processes all resultset files in the coverage directory' do
      minifier.minify
      expect(Dir).to have_received(:glob).with(root_dir.join('coverage', '*', '.resultset.json'))
    end
  end
end
