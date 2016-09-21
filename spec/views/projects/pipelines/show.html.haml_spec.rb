require 'spec_helper'

describe 'projects/pipelines/show' do
  include Devise::Test::ControllerHelpers

  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.id) }

  before do
    controller.prepend_view_path('app/views/projects')

    create_build('build', 0, 'build', :success)
    create_build('test', 1, 'rspec 0:2', :pending)
    create_build('test', 1, 'rspec 1:2', :running)
    create_build('test', 1, 'spinach 0:2', :created)
    create_build('test', 1, 'spinach 1:2', :created)
    create_build('test', 1, 'audit', :created)
    create_build('deploy', 2, 'production', :created)

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
    expect(rendered).to have_text('spinach')
    expect(rendered).to have_text('rspec 0:2')
    expect(rendered).to have_text('production')
    expect(rendered).to have_text('jenkins')
  end

  private

  def create_build(stage, stage_idx, name, status)
    create(:ci_build, pipeline: pipeline, stage: stage, stage_idx: stage_idx, name: name, status: status)
  end
end
