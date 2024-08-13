# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobEntity, feature_category: :continuous_integration do
  let(:user) { create(:user) }
  let(:job) { create(:ci_build, :running) }
  let(:project) { job.project }
  let(:request) { double('request') }

  before do
    stub_not_protect_default_branch
    allow(request).to receive(:current_user).and_return(user)

    project.add_developer(user)
  end

  let(:entity) do
    described_class.new(job, request: request)
  end

  subject { entity.as_json }

  it 'contains started' do
    expect(subject).to include(:started)
    expect(subject[:started]).to eq(true)
  end

  it 'contains complete to indicate if a pipeline is completed' do
    expect(subject).to include(:complete)
  end

  it 'contains paths to job page action' do
    expect(subject).to include(:build_path)
  end

  it 'does not contain sensitive information' do
    expect(subject).not_to include(/token/)
    expect(subject).not_to include(/variables/)
  end

  it 'contains whether it is playable' do
    expect(subject[:playable]).to eq job.playable?
  end

  it 'contains timestamps' do
    expect(subject).to include(:created_at, :updated_at)
  end

  it 'contains details' do
    expect(subject).to include :status
    expect(subject[:status]).to include :icon, :favicon, :text, :label, :tooltip
  end

  it 'contains queued_at' do
    expect(subject).to include :queued_at
  end

  it 'contains queued_duration' do
    expect(subject).to include :queued_duration
  end

  context 'when job is retryable' do
    before do
      job.update!(status: :failed)
    end

    it 'contains cancel path' do
      expect(subject).to include(:retry_path)
    end
  end

  context 'when job is cancelable' do
    before do
      job.update!(status: :running)
    end

    it 'contains cancel path' do
      expect(subject).to include(:cancel_path)
    end
  end

  context 'when job is a regular job' do
    it 'does not contain path to play action' do
      expect(subject).not_to include(:play_path)
    end

    it 'is not a playable build' do
      expect(subject[:playable]).to be false
    end
  end

  context 'when job is a manual action' do
    let(:job) { create(:ci_build, :manual) }

    context 'when user is allowed to trigger action' do
      before do
        project.add_developer(user)

        create(:protected_branch, :developers_can_merge, name: job.ref, project: job.project)
      end

      it 'contains path to play action' do
        expect(subject).to include(:play_path)
      end

      it 'is a playable action' do
        expect(subject[:playable]).to be true
      end
    end

    context 'when user is not allowed to trigger action' do
      before do
        allow(job.project).to receive(:empty_repo?).and_return(false)

        create(:protected_branch, :no_one_can_push, name: job.ref, project: job.project)
      end

      it 'does not contain path to play action' do
        expect(subject).not_to include(:play_path)
      end

      it 'is not a playable action' do
        expect(subject[:playable]).to be false
      end
    end
  end

  context 'when job is scheduled' do
    let(:job) { create(:ci_build, :scheduled) }

    it 'contains path to unschedule action' do
      expect(subject).to include(:unschedule_path)
    end

    it 'contains scheduled_at' do
      expect(subject[:scheduled]).to be_truthy
      expect(subject[:scheduled_at]).to eq(job.scheduled_at)
    end
  end

  context 'when job is running' do
    let_it_be(:job) { create(:ci_build, :running) }

    it 'contains started_at' do
      expect(subject[:started]).to be_truthy
      expect(subject[:started_at]).to eq(job.started_at)
    end
  end

  context 'when job is generic commit status' do
    let(:job) { create(:generic_commit_status, target_url: 'http://google.com') }

    it 'contains paths to target action' do
      expect(subject).to include(:build_path)
    end

    it 'does not contain paths to other action paths' do
      expect(subject).not_to include(:retry_path, :cancel_path, :play_path)
    end

    it 'contains timestamps' do
      expect(subject).to include(:created_at, :updated_at)
    end

    it 'contains details' do
      expect(subject).to include :status
      expect(subject[:status]).to include :icon, :favicon, :text, :label, :tooltip
    end
  end

  context 'when job failed' do
    let(:job) { create(:ci_build, :api_failure) }

    it 'contains details' do
      expect(subject[:status]).to include :icon, :favicon, :text, :label, :tooltip
    end

    it 'states that it failed' do
      expect(subject[:status][:label]).to eq(s_('CiStatusLabel|failed'))
    end

    it 'indicates the failure reason on tooltip' do
      expect(subject[:status][:tooltip]).to eq("#{s_('CiStatusLabel|Failed')} - (API failure)")
    end

    it 'includes a callout message with a verbose output' do
      expect(subject[:callout_message]).to eq('There has been an API failure, please try again')
    end

    it 'states that it is not recoverable' do
      expect(subject[:recoverable]).to be_truthy
    end
  end

  context 'when job is allowed to fail' do
    let(:job) { create(:ci_build, :allowed_to_fail, :api_failure) }

    it 'contains details' do
      expect(subject[:status]).to include :icon, :favicon, :text, :label, :tooltip
    end

    it 'states that it failed' do
      expect(subject[:status][:label]).to eq('failed (allowed to fail)')
    end

    it 'indicates the failure reason on tooltip' do
      expect(subject[:status][:tooltip]).to eq("#{s_('CiStatusLabel|Failed')} - (API failure) (allowed to fail)")
    end

    it 'includes a callout message with a verbose output' do
      expect(subject[:callout_message]).to eq('There has been an API failure, please try again')
    end

    it 'states that it is not recoverable' do
      expect(subject[:recoverable]).to be_truthy
    end
  end

  context 'when the job failed with a script failure' do
    let(:job) { create(:ci_build, :failed, :script_failure) }

    it 'does not include callout message or recoverable keys' do
      expect(subject).not_to include('callout_message')
      expect(subject).not_to include('recoverable')
    end
  end

  context 'when job failed and is recoverable' do
    let(:job) { create(:ci_build, :api_failure) }

    it 'states it is recoverable' do
      expect(subject[:recoverable]).to be_truthy
    end
  end

  context 'when job passed' do
    let(:job) { create(:ci_build, :success) }

    it 'does not include callout message or recoverable keys' do
      expect(subject).not_to include('callout_message')
      expect(subject).not_to include('recoverable')
    end
  end

  context 'when job is a bridge' do
    let(:job) { create(:ci_bridge) }

    it 'does not include build path' do
      expect(subject).not_to include(:build_path)
    end

    it 'does not include cancel path' do
      expect(subject).not_to include(:cancel_path)
    end
  end
end
