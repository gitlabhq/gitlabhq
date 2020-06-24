# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Build::Associations do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, developer_projects: [project]) }
  let(:pipeline) { Ci::Pipeline.new }
  let(:step) { described_class.new(pipeline, command) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      source: :push,
      origin_ref: 'master',
      checkout_sha: project.commit.id,
      after_sha: nil,
      before_sha: nil,
      trigger_request: nil,
      schedule: nil,
      merge_request: nil,
      project: project,
      current_user: user,
      bridge: bridge)
  end

  context 'when a bridge is passed in to the pipeline creation' do
    let(:bridge) { create(:ci_bridge) }

    it 'links the pipeline to the upstream bridge job' do
      step.perform!

      expect(pipeline.source_pipeline).to be_present
      expect(pipeline.source_pipeline).to be_valid
      expect(pipeline.source_pipeline).to have_attributes(
        source_pipeline: bridge.pipeline, source_project: bridge.project,
        source_bridge: bridge, project: project
      )
    end

    it 'never breaks the chain' do
      step.perform!

      expect(step.break?).to eq(false)
    end
  end

  context 'when a bridge is not passed in to the pipeline creation' do
    let(:bridge) { nil }

    it 'leaves the source pipeline empty' do
      step.perform!

      expect(pipeline.source_pipeline).to be_nil
    end

    it 'never breaks the chain' do
      step.perform!

      expect(step.break?).to eq(false)
    end
  end
end
