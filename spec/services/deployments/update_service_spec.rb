# frozen_string_literal: true

require 'spec_helper'

describe Deployments::UpdateService do
  let(:deploy) { create(:deployment) }

  describe '#execute' do
    it 'can update the status to running' do
      expect(described_class.new(deploy, status: 'running').execute)
        .to be_truthy

      expect(deploy).to be_running
    end

    it 'can update the status to success' do
      expect(described_class.new(deploy, status: 'success').execute)
        .to be_truthy

      expect(deploy).to be_success
    end

    it 'can update the status to failed' do
      expect(described_class.new(deploy, status: 'failed').execute)
        .to be_truthy

      expect(deploy).to be_failed
    end

    it 'can update the status to canceled' do
      expect(described_class.new(deploy, status: 'canceled').execute)
        .to be_truthy

      expect(deploy).to be_canceled
    end

    it 'returns false when the status is not supported' do
      expect(described_class.new(deploy, status: 'kittens').execute)
        .to be_falsey
    end

    it 'links merge requests when changing the status to success', :sidekiq_inline do
      mr = create(
        :merge_request,
        :merged,
        target_project: deploy.project,
        source_project: deploy.project,
        target_branch: 'master',
        source_branch: 'foo'
      )

      described_class.new(deploy, status: 'success').execute

      expect(deploy.merge_requests).to eq([mr])
    end
  end
end
