require 'spec_helper'

describe 'projects/pipelines/_stage' do
  let(:project) { create(:project, :repository) }
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
      create(:ci_build, name: 'test:build', stage: stage.name, pipeline: pipeline, retried: true)
      create(:ci_build, name: 'test:build', stage: stage.name, pipeline: pipeline)
    end

    it 'shows only latest builds' do
      render

      expect(rendered).to have_text 'test:build', count: 1
    end
  end

  context 'when there are multiple builds' do
    before do
      HasStatus::AVAILABLE_STATUSES.each do |status|
        create_build(status)
      end
    end

    it 'shows them in order' do
      render

      expect(rendered).to have_text(HasStatus::ORDERED_STATUSES.join(" "))
    end

    def create_build(status)
      create(:ci_build, name: status, status: status,
                        pipeline: pipeline, stage: stage.name)
    end
  end
end
