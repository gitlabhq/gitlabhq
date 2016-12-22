require 'spec_helper'

describe 'projects/pipelines/_stage', :view do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:stage) { build(:ci_stage, pipeline: pipeline) }

  before do
    assign :stage, stage

    create(:ci_build, name: 'test:build',
                      stage: stage.name,
                      pipeline: pipeline)
  end

  it 'shows the builds in the stage' do
    render

    expect(rendered).to have_text 'test:build'
  end
end
