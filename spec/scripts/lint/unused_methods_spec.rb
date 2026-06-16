# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'
require_relative '../../../scripts/lint/unused_methods'

RSpec.describe Lint::UnusedMethods, feature_category: :tooling do
  let(:temp_dir) { Dir.mktmpdir }
  let(:excluded_methods_path) { File.join(temp_dir, 'excluded_methods.yml') }
  let(:potential_methods_path) { File.join(temp_dir, 'potential_methods_to_remove.yml') }

  let(:linter) do
    described_class.new(
      excluded_methods_path: excluded_methods_path,
      potential_methods_path: potential_methods_path
    )
  end

  before do
    # Create empty config files
    File.write(excluded_methods_path, {}.to_yaml)
    File.write(potential_methods_path, {}.to_yaml)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#file_extensions_glob' do
    it 'includes .rb files' do
      expect(linter.file_extensions_glob).to include('{ee/,}app/**/*.rb')
    end

    it 'includes .haml files' do
      expect(linter.file_extensions_glob).to include('{ee/,}app/**/*.haml')
    end

    it 'includes .erb files' do
      expect(linter.file_extensions_glob).to include('{ee/,}app/**/*.erb')
    end

    it 'includes .builder files' do
      expect(linter.file_extensions_glob).to include('{ee/,}app/**/*.builder')
    end

    it 'searches in app, config, gems, and lib directories' do
      globs = linter.file_extensions_glob

      expect(globs).to include('{ee/,}app/**/*.rb')
      expect(globs).to include('config/**/*.rb')
      expect(globs).to include('gems/**/*.rb')
      expect(globs).to include('{ee/,}lib/**/*.rb')
    end

    context 'with custom extensions' do
      let(:linter) do
        described_class.new(
          excluded_methods_path: excluded_methods_path,
          potential_methods_path: potential_methods_path,
          extensions: %w[rb custom]
        )
      end

      it 'uses the custom extensions' do
        globs = linter.file_extensions_glob

        expect(globs).to include('{ee/,}app/**/*.rb')
        expect(globs).to include('{ee/,}app/**/*.custom')
        expect(globs).not_to include('{ee/,}app/**/*.haml')
      end
    end
  end

  describe 'EXTENSIONS constant' do
    it 'includes builder extension for Atom feed templates' do
      expect(described_class::EXTENSIONS).to include('builder')
    end

    it 'includes all expected extensions' do
      expect(described_class::EXTENSIONS).to contain_exactly('rb', 'haml', 'erb', 'builder')
    end
  end

  describe '#ee_directory_exists?' do
    context 'when ee directory exists' do
      before do
        allow(Dir).to receive(:exist?).with('ee').and_return(true)
      end

      it 'returns true' do
        expect(linter.ee_directory_exists?).to be true
      end
    end

    context 'when ee directory does not exist' do
      before do
        allow(Dir).to receive(:exist?).with('ee').and_return(false)
      end

      it 'returns false' do
        expect(linter.ee_directory_exists?).to be false
      end
    end
  end

  describe '#run' do
    context 'when ee directory does not exist' do
      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(false)
      end

      it 'returns false and exits early' do
        expect(linter).not_to receive(:load_source_files)
        expect(linter.run).to be false
      end
    end

    context 'when ee directory exists' do
      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(true)
        allow(Dir).to receive(:glob).and_return([])
      end

      it 'loads source files' do
        expect(linter).to receive(:load_source_files).and_call_original
        linter.run
      end
    end
  end

  describe 'method detection in builder files' do
    # This test verifies the fix for the issue where methods called from
    # .builder files (like Atom feeds) were incorrectly flagged as unused
    it 'includes builder in the default extensions' do
      expect(described_class::EXTENSIONS).to include('builder')
    end

    it 'generates glob patterns for builder files' do
      globs = linter.file_extensions_glob
      builder_globs = globs.select { |g| g.include?('.builder') }

      expect(builder_globs).not_to be_empty
      expect(builder_globs).to include('{ee/,}app/**/*.builder')
    end
  end

  describe 'integration with real file patterns' do
    # Verify that the glob patterns would match actual builder files
    it 'would match app/views builder files' do
      # File.fnmatch doesn't support brace expansion, but Dir.glob does
      # Test the individual patterns that Dir.glob would expand to
      expect(File.fnmatch('app/**/*.builder', 'app/views/events/_event.atom.builder')).to be true
      expect(File.fnmatch('app/**/*.builder', 'app/views/projects/show.atom.builder')).to be true
      expect(File.fnmatch('ee/app/**/*.builder', 'ee/app/views/some_view.builder')).to be true
    end

    it 'would not match builder files outside app directory' do
      expect(File.fnmatch('app/**/*.builder', 'spec/fixtures/test.builder')).to be false
      expect(File.fnmatch('ee/app/**/*.builder', 'spec/fixtures/test.builder')).to be false
    end
  end
end
