# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayManualStageService, '#execute', feature_category: :continuous_integration do
  let(:current_user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, user: current_user) }
  let(:project) { pipeline.project }
  let(:downstream_project) { create(:project) }
  let(:service) { described_class.new(project, current_user, pipeline: pipeline) }
  let(:stage_status) { 'manual' }

  let(:stage) do
    create(:ci_stage, pipeline: pipeline, project: project, name: 'test')
  end

  before do
    project.add_maintainer(current_user)
    downstream_project.add_maintainer(current_user)
    create_builds_for_stage(status: stage_status)
    create_bridge_for_stage(status: stage_status)
  end

  context 'when pipeline has manual processables' do
    before do
      service.execute(stage)
    end

    it 'starts manual processables from pipeline' do
      expect(pipeline.processables.manual.count).to eq(0)
    end

    it 'updates manual processables' do
      pipeline.processables.each do |processable|
        expect(processable.user).to eq(current_user)
      end
    end
  end

  context 'when pipeline has no manual processables' do
    let(:stage_status) { 'failed' }

    before do
      service.execute(stage)
    end

    it 'does not update the processables' do
      expect(pipeline.processables.failed.count).to eq(4)
    end
  end

  context 'when user does not have permission on a specific processable' do
    before do
      allow_next_instance_of(Ci::Processable) do |instance|
        allow(instance).to receive(:play).and_raise(Gitlab::Access::AccessDeniedError)
      end

      service.execute(stage)
    end

    it 'logs the error' do
      expect(Gitlab::AppLogger).to receive(:error)
        .exactly(stage.processables.manual.count)

      service.execute(stage)
    end
  end

  private

  def create_builds_for_stage(options)
    options.merge!({
      when: 'manual',
      pipeline: pipeline,
      stage_id: stage.id,
      user: pipeline.user
    })

    create_list(:ci_build, 3, options)
  end

  def create_bridge_for_stage(options)
    options.merge!({
      when: 'manual',
      pipeline: pipeline,
      stage_id: stage.id,
      user: pipeline.user,
      downstream: downstream_project
    })

    create(:ci_bridge, options)
  end
end
