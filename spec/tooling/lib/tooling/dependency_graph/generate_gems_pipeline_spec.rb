# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'
require 'yaml'

require_relative '../../../../../tooling/lib/tooling/dependency_graph/generate_gems_pipeline'

RSpec.describe Tooling::DependencyGraph::GenerateGemsPipeline, feature_category: :tooling do
  subject(:generate) do
    described_class.new(
      output_path: output_path,
      parent_pipeline_id: '123',
      changed_files_path: changed_files_path,
      root: root
    ).generate!
  end

  let(:root) { Dir.mktmpdir }
  let(:output_path) { File.join(root, 'gems-pipeline.yml') }
  let(:changed_files_path) { File.join(root, 'changed_files.txt') }
  let(:pipeline) { YAML.safe_load_file(output_path) }

  def write_file(path, content = '')
    FileUtils.mkdir_p(File.join(root, File.dirname(path)))
    File.write(File.join(root, path), content)
  end

  def write_lockfile(path, *remotes)
    write_file(path, remotes.map { |remote| "PATH\n  remote: #{remote}\n  specs:\n\n" }.join)
  end

  before do
    write_lockfile('Gemfile.lock', 'gems/gem-a', 'vendor/gems/gem-b')
    write_lockfile('gems/gem-a/Gemfile.lock', '../../vendor/gems/gem-b', '.')
    write_lockfile('vendor/gems/gem-b/Gemfile.lock', '.')
    write_lockfile('gems/gem-without-ci/Gemfile.lock', '../../vendor/gems/gem-b', '.')
    write_file('gems/gem-a/.gitlab-ci.yml')
    write_file('vendor/gems/gem-b/.gitlab-ci.yml')
    write_file('.gitlab-ci.yml')
    %w[gems/gem-a vendor/gems/gem-b gems/gem-without-ci].each do |dir|
      write_file("#{dir}/#{File.basename(dir)}.gemspec")
    end
  end

  after do
    FileUtils.rm_rf(root)
  end

  context 'when a gem changes' do
    before do
      write_file('changed_files.txt', "app/models/user.rb\nvendor/gems/gem-b/lib/gem_b.rb")
    end

    it 'triggers the pipelines of the changed gem and of the gems that depend on it' do
      generate

      expect(pipeline.keys).to match_array(['gems gem-a', 'gems gem-b'])
      expect(pipeline['gems gem-b']).to eq(
        'trigger' => { 'include' => 'vendor/gems/gem-b/.gitlab-ci.yml', 'strategy' => 'depend' },
        'inherit' => { 'variables' => false },
        'variables' => {
          'FF_NETWORK_PER_BUILD' => 'true',
          'PARENT_PIPELINE_ID' => '123',
          'CI_FETCH_REPO_GIT_STRATEGY' => 'none'
        }
      )
    end
  end

  context 'when a gem that nothing depends on changes' do
    before do
      write_file('changed_files.txt', 'gems/gem-a/lib/gem_a.rb')
    end

    it 'triggers only the pipeline of the changed gem' do
      generate

      expect(pipeline.keys).to eq(['gems gem-a'])
    end
  end

  context 'when only the monolith changes' do
    before do
      write_file('changed_files.txt', 'app/models/user.rb')
    end

    it 'generates a job that does nothing' do
      generate

      expect(pipeline.keys).to eq([described_class::NO_GEMS_JOB_NAME])
    end
  end

  context 'when no changed files are given' do
    let(:changed_files_path) { nil }

    it 'triggers the pipelines of all the gems' do
      generate

      expect(pipeline.keys).to match_array(['gems gem-a', 'gems gem-b'])
    end
  end

  context 'when the changed files are not available' do
    it 'triggers the pipelines of all the gems' do
      generate

      expect(pipeline.keys).to match_array(['gems gem-a', 'gems gem-b'])
    end
  end

  context 'when the changed files are empty' do
    before do
      write_file('changed_files.txt')
    end

    it 'triggers the pipelines of all the gems' do
      generate

      expect(pipeline.keys).to match_array(['gems gem-a', 'gems gem-b'])
    end
  end
end
