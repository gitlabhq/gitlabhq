# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Bridge::Factory, feature_category: :continuous_integration do
  include Ci::PipelineMessageHelpers

  let(:user) { create(:user) }
  let(:project) { bridge.project }
  let(:status) { factory.fabricate! }
  let(:factory) { described_class.new(bridge, user) }

  before do
    stub_not_protect_default_branch

    project.add_developer(user)
  end

  context 'when bridge is created' do
    let(:bridge) { create_bridge(:created) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Created
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|Created')
      expect(status.icon).to eq 'status_created'
      expect(status.favicon).to eq 'favicon_status_created'
      expect(status.label).to eq 'created'
      expect(status).not_to have_details
      expect(status).not_to have_action
    end
  end

  context 'when bridge is failed' do
    let(:bridge) { create_bridge(:failed) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Failed
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Bridge::Retryable,
                Gitlab::Ci::Status::Bridge::Failed]
    end

    it 'fabricates a failed bridge status' do
      expect(status).to be_a Gitlab::Ci::Status::Bridge::Failed
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|Failed')
      expect(status.icon).to eq 'status_failed'
      expect(status.favicon).to eq 'favicon_status_failed'
      expect(status.label).to eq 'failed'
      expect(status.status_tooltip).to eq "#{s_('CiStatusLabel|Failed')} - (unknown failure)"
      expect(status).not_to have_details
      expect(status).to have_action
    end

    context 'failed with downstream_pipeline_creation_failed' do
      before do
        bridge.options = { downstream_errors: [sanitize_message(Ci::Pipeline.rules_failure_message), 'other error'] }
        bridge.failure_reason = 'downstream_pipeline_creation_failed'
      end

      it 'fabricates correct status_tooltip' do
        expect(status.status_tooltip).to eq(
          "#{s_('CiStatusLabel|Failed')} - (downstream pipeline can not be created, #{sanitize_message(Ci::Pipeline.rules_failure_message)}, other error)"
        )
      end
    end
  end

  context 'when bridge is a manual action' do
    let(:bridge) { create_bridge(:playable) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Manual
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Bridge::Manual,
                Gitlab::Ci::Status::Bridge::Play,
                Gitlab::Ci::Status::Bridge::Action]
    end

    it 'fabricates action detailed status' do
      expect(status).to be_a Gitlab::Ci::Status::Bridge::Action
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|Manual')
      expect(status.group).to eq 'manual'
      expect(status.icon).to eq 'status_manual'
      expect(status.favicon).to eq 'favicon_status_manual'
      expect(status.illustration).to include(:image, :size, :title, :content)
      expect(status.label).to include 'manual play action'
      expect(status).not_to have_details
      expect(status.action_path).to include 'play'
    end

    context 'when user has ability to play action' do
      before do
        bridge.downstream_project.add_developer(user)
      end

      it 'fabricates status that has action' do
        expect(status).to have_action
      end
    end

    context 'when user does not have ability to play action' do
      it 'fabricates status that has no action' do
        expect(status).not_to have_action
      end
    end
  end

  context 'when bridge is waiting for resource' do
    let(:bridge) { create_bridge(:waiting_for_resource, :resource_group) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::WaitingForResource
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq 'Waiting'
      expect(status.group).to eq 'waiting-for-resource'
      expect(status.icon).to eq 'status_pending'
      expect(status.favicon).to eq 'favicon_status_pending'
      expect(status.illustration).to include(:image, :size, :title)
      expect(status).not_to have_details
    end
  end

  context 'when the bridge is successful and therefore retryable' do
    let(:bridge) { create(:ci_bridge, :success) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Success
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Bridge::Retryable]
    end

    it 'fabricates a retryable build status' do
      expect(status).to be_a Gitlab::Ci::Status::Bridge::Retryable
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|Passed')
      expect(status.icon).to eq 'status_success'
      expect(status.favicon).to eq 'favicon_status_success'
      expect(status).to have_action
    end
  end

  private

  def create_bridge(*traits)
    upstream_project = create(:project, :repository)
    downstream_project = create(:project, :repository)
    upstream_pipeline = create(:ci_pipeline, :running, project: upstream_project)
    trigger = { trigger: { project: downstream_project.full_path, branch: 'feature' } }

    create(:ci_bridge, *traits, options: trigger, pipeline: upstream_pipeline)
  end
end
