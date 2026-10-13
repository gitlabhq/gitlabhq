# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../tooling/lib/tooling/dependency_graph/graph'

RSpec.describe 'gems:dependency_graph', feature_category: :tooling do
  let(:graph) do
    instance_double(Tooling::DependencyGraph::Graph,
      to_h: { '.' => ['gems/gem-a'], 'gems/gem-a' => [] },
      to_mermaid: "flowchart LR\n  monolith --> gems_gem_a")
  end

  before do
    Rake.application.rake_require('tasks/gems/dependency_graph')

    allow(Tooling::DependencyGraph::Graph)
      .to receive(:new).with(root: File.expand_path('../../..', __dir__)).and_return(graph)
  end

  it 'prints the dependency graph of the repository as JSON' do
    expect { run_rake_task('gems:dependency_graph') }
      .to output("#{Gitlab::Json.pretty_generate(graph.to_h)}\n").to_stdout
  end

  it 'prints the dependency graph of the repository as Mermaid' do
    expect { run_rake_task('gems:dependency_graph', 'mermaid') }
      .to output("#{graph.to_mermaid}\n").to_stdout
  end

  it 'fails with an unknown format' do
    expect { run_rake_task('gems:dependency_graph', 'dot') }
      .to raise_error(SystemExit).and output(/Unknown format 'dot'/).to_stderr
  end
end
