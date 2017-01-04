require 'spec_helper'

describe 'projects/pipelines/_stage', :view do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:stage) { build(:ci_stage, pipeline: pipeline) }

  before do
    assign :stage, stage
  end

  context 'when there are only latest builds present' do
    before do
      create(:ci_build, name: 'test:build',
                        stage: stage.name,
                        pipeline: pipeline)
    end

    it 'shows the builds in the stage' do
      render

      expect(rendered).to have_text 'test:build'
    end
  end

  context 'when build belongs to different stage' do
    before do
      create(:ci_build, name: 'test:build',
                        stage: 'other:stage',
                        pipeline: pipeline)
    end

    it 'does not render build' do
      render

      expect(rendered).not_to have_text 'test:build'
    end
  end

  context 'when there are retried builds present' do
    before do
      create_list(:ci_build, 2, name: 'test:build',
                                stage: stage.name,
                                pipeline: pipeline)
    end

    it 'shows only latest builds' do
      render

      expect(rendered).to have_text 'test:build', count: 1
    end
  end
end
