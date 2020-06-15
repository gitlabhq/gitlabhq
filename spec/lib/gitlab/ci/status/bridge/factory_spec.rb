# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::Bridge::Factory do
  let(:user) { create(:user) }
  let(:project) { bridge.project }
  let(:status) { factory.fabricate! }
  let(:factory) { described_class.new(bridge, user) }

  before do
    stub_not_protect_default_branch

    project.add_developer(user)
  end

  context 'when bridge is created' do
    let(:bridge) { create(:ci_bridge) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Created
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|created')
      expect(status.icon).to eq 'status_created'
      expect(status.favicon).to eq 'favicon_status_created'
      expect(status.label).to be_nil
      expect(status).not_to have_details
      expect(status).not_to have_action
    end
  end

  context 'when bridge is failed' do
    let(:bridge) { create(:ci_bridge, :failed) }

    it 'matches correct core status' do
      expect(factory.core_status).to be_a Gitlab::Ci::Status::Failed
    end

    it 'matches correct extended statuses' do
      expect(factory.extended_statuses)
        .to eq [Gitlab::Ci::Status::Bridge::Failed]
    end

    it 'fabricates a failed bridge status' do
      expect(status).to be_a Gitlab::Ci::Status::Bridge::Failed
    end

    it 'fabricates status with correct details' do
      expect(status.text).to eq s_('CiStatusText|failed')
      expect(status.icon).to eq 'status_failed'
      expect(status.favicon).to eq 'favicon_status_failed'
      expect(status.label).to be_nil
      expect(status.status_tooltip).to eq "#{s_('CiStatusText|failed')} - (unknown failure)"
      expect(status).not_to have_details
      expect(status).not_to have_action
    end

    context 'failed with downstream_pipeline_creation_failed' do
      before do
        bridge.options = { downstream_errors: ['No stages / jobs for this pipeline.', 'other error'] }
        bridge.failure_reason = 'downstream_pipeline_creation_failed'
      end

      it 'fabricates correct status_tooltip' do
        expect(status.status_tooltip).to eq(
          "#{s_('CiStatusText|failed')} - (downstream pipeline can not be created, No stages / jobs for this pipeline., other error)"
        )
      end
    end
  end
end
