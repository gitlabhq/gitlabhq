require 'spec_helper'

describe JobEntity do
  let(:user) { create(:user) }
  let(:job) { create(:ci_build) }
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

  context 'when job is retryable' do
    before do
      job.update(status: :failed)
    end

    it 'contains cancel path' do
      expect(subject).to include(:retry_path)
    end
  end

  context 'when job is cancelable' do
    before do
      job.update(status: :running)
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

        create(:protected_branch, :developers_can_merge,
               name: job.ref, project: job.project)
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

        create(:protected_branch, :no_one_can_push,
               name: job.ref, project: job.project)
      end

      it 'does not contain path to play action' do
        expect(subject).not_to include(:play_path)
      end

      it 'is not a playable action' do
        expect(subject[:playable]).to be false
      end
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
    let(:job) { create(:ci_build, :script_failure) }

    it 'contains details' do
      expect(subject[:status]).to include :icon, :favicon, :text, :label, :tooltip
    end

    it 'states that it failed' do
      expect(subject[:status][:label]).to eq('failed')
    end

    it 'should indicate the failure reason on tooltip' do
      expect(subject[:status][:tooltip]).to eq('failed <br> (script failure)')
    end

    it 'should include a callout message with a verbose output' do
      expect(subject[:callout_message]).to eq('There has been a script failure. Check the job log for more information')
    end

    it 'should state that it is not recoverable' do
      expect(subject[:recoverable]).to be_falsy
    end
  end

  context 'when job is allowed to fail' do
    let(:job) { create(:ci_build, :allowed_to_fail, :script_failure) }

    it 'contains details' do
      expect(subject[:status]).to include :icon, :favicon, :text, :label, :tooltip
    end

    it 'states that it failed' do
      expect(subject[:status][:label]).to eq('failed (allowed to fail)')
    end

    it 'should indicate the failure reason on tooltip' do
      expect(subject[:status][:tooltip]).to eq('failed <br> (script failure) (allowed to fail)')
    end

    it 'should include a callout message with a verbose output' do
      expect(subject[:callout_message]).to eq('There has been a script failure. Check the job log for more information')
    end

    it 'should state that it is not recoverable' do
      expect(subject[:recoverable]).to be_falsy
    end
  end

  context 'when job failed and is recoverable' do
    let(:job) { create(:ci_build, :api_failure) }

    it 'should state it is recoverable' do
      expect(subject[:recoverable]).to be_truthy
    end
  end

  context 'when job passed' do
    let(:job) { create(:ci_build, :success) }

    it 'should not include callout message or recoverable keys' do
      expect(subject).not_to include('callout_message')
      expect(subject).not_to include('recoverable')
    end
  end
end
