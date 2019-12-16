# frozen_string_literal: true

require 'spec_helper'

describe Ci::PlayManualStageService, '#execute' do
  let(:current_user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, user: current_user) }
  let(:project) { pipeline.project }
  let(:service) { described_class.new(project, current_user, pipeline: pipeline) }
  let(:stage_status) { 'manual' }

  let(:stage) do
    create(:ci_stage_entity,
           pipeline: pipeline,
           project: project,
           name: 'test')
  end

  before do
    project.add_maintainer(current_user)
    create_builds_for_stage(status: stage_status)
  end

  context 'when pipeline has manual builds' do
    before do
      service.execute(stage)
    end

    it 'starts manual builds from pipeline' do
      expect(pipeline.builds.manual.count).to eq(0)
    end

    it 'updates manual builds' do
      pipeline.builds.each do |build|
        expect(build.user).to eq(current_user)
      end
    end
  end

  context 'when pipeline has no manual builds' do
    let(:stage_status) { 'failed' }

    before do
      service.execute(stage)
    end

    it 'does not update the builds' do
      expect(pipeline.builds.failed.count).to eq(3)
    end
  end

  context 'when user does not have permission on a specific build' do
    before do
      allow_next_instance_of(Ci::Build) do |instance|
        allow(instance).to receive(:play).and_raise(Gitlab::Access::AccessDeniedError)
      end

      service.execute(stage)
    end

    it 'logs the error' do
      expect(Gitlab::AppLogger).to receive(:error)
        .exactly(stage.builds.manual.count)

      service.execute(stage)
    end
  end

  def create_builds_for_stage(options)
    options.merge!({
      when: 'manual',
      pipeline: pipeline,
      stage: stage.name,
      stage_id: stage.id,
      user: pipeline.user
    })

    create_list(:ci_build, 3, options)
  end
end
