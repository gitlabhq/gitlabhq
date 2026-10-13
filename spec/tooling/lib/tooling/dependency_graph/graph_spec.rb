# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../../../../../tooling/lib/tooling/dependency_graph/graph'

RSpec.describe Tooling::DependencyGraph::Graph, feature_category: :tooling do
  subject(:graph) { described_class.new(root: root) }

  let(:root) { Dir.mktmpdir }

  def write_gem(dir)
    FileUtils.mkdir_p(File.join(root, dir))
    File.write(File.join(root, dir, "#{File.basename(dir)}.gemspec"), '')
  end

  def write_lockfile(path, *remotes)
    content = remotes.map { |remote| "PATH\n  remote: #{remote}\n  specs:\n    some-gem (0.1.0)\n\n" }.join
    content += "GEM\n  remote: https://rubygems.org/\n  specs:\n    rake (13.0.0)\n"

    FileUtils.mkdir_p(File.join(root, File.dirname(path)))
    File.write(File.join(root, path), content)
  end

  before do
    write_lockfile('Gemfile.lock', 'gems/gem-a', 'vendor/gems/gem-c')
    write_lockfile('Gemfile.next.lock', 'gems/gem-a', 'gems/gem-d')
    write_lockfile('gems/gem-a/Gemfile.lock', '../gem-b', '.')
    write_lockfile('gems/gem-b/Gemfile.lock', '.')
    write_lockfile('gems/gem-d/Gemfile.lock', '.')
    write_lockfile('gems/gem-d/Gemfile.next.lock', '../gem-b', '.')
    write_lockfile('vendor/gems/gem-c/Gemfile.lock', '../../../gems/gem-b', '.')
    %w[gems/gem-a gems/gem-b gems/gem-d gems/gem-without-lockfile vendor/gems/gem-c].each { |dir| write_gem(dir) }
    FileUtils.mkdir_p(File.join(root, 'gems/not-a-gem'))
  end

  after do
    FileUtils.rm_rf(root)
  end

  describe '#to_h' do
    it 'maps the monolith and each in-repo gem to the in-repo gems it depends on' do
      expect(graph.to_h).to eq(
        '.' => %w[gems/gem-a gems/gem-d vendor/gems/gem-c],
        'gems/gem-a' => %w[gems/gem-b],
        'gems/gem-b' => [],
        'gems/gem-d' => %w[gems/gem-b],
        'gems/gem-without-lockfile' => [],
        'vendor/gems/gem-c' => %w[gems/gem-b]
      )
    end
  end

  describe '#to_mermaid' do
    it 'renders each bundle as a node and each dependency as an edge' do
      expect(graph.to_mermaid).to eq(<<~MERMAID.chomp)
        flowchart LR
          monolith["monolith"]
          gems_gem_a["gems/gem-a"]
          gems_gem_b["gems/gem-b"]
          gems_gem_d["gems/gem-d"]
          gems_gem_without_lockfile["gems/gem-without-lockfile"]
          vendor_gems_gem_c["vendor/gems/gem-c"]
          monolith --> gems_gem_a
          monolith --> gems_gem_d
          monolith --> vendor_gems_gem_c
          gems_gem_a --> gems_gem_b
          gems_gem_d --> gems_gem_b
          vendor_gems_gem_c --> gems_gem_b
      MERMAID
    end
  end
end
