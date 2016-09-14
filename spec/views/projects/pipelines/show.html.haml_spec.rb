require 'spec_helper'

describe 'projects/pipelines/show' do
  include Devise::TestHelpers

  let(:project) { create(:project) }
  let(:pipeline) do
    create(:ci_empty_pipeline, project: project,
           sha: project.commit.id)
  end

  before do
    create_build('build', 0, 'build')
    create_build('test', 1, 'rspec 0 2')
    create_build('test', 1, 'rspec 1 2')
    create_build('test', 1, 'audit')
    create_build('deploy', 2, 'production')

    create(:generic_commit_status, pipeline: pipeline, stage: 'external', name: 'jenkins', stage_idx: 3)

    assign(:project, project)
    assign(:pipeline, pipeline)

    allow(view).to receive(:can?).and_return(true)
  end

  it 'shows a graph with grouped stages' do
    render

    expect(rendered).to have_css('.pipeline-graph')
    expect(rendered).to have_css('.grouped-pipeline-dropdown')

    # stages
    expect(rendered).to have_text('Build')
    expect(rendered).to have_text('Test')
    expect(rendered).to have_text('Deploy')
    expect(rendered).to have_text('External')

    # builds
    expect(rendered).to have_text('rspec')
    expect(rendered).to have_text('rspec 0:1')
    expect(rendered).to have_text('production')
    expect(rendered).to have_text('jenkins')
  end

  private

  def create_build(stage, stage_idx, name)
    create(:ci_build, pipeline: pipeline, stage: stage, stage_idx: stage_idx, name: name)
  end
end
