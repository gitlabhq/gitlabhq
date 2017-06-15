require 'spec_helper'

describe JobEntity do
  let(:user) { create(:user) }
  let(:job) { create(:ci_build) }
  let(:project) { job.project }
  let(:request) { double('request') }

  before do
    allow(request).to receive(:current_user).and_return(user)
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
    expect(subject[:status]).to include :icon, :favicon, :text, :label
  end

  context 'when job is retryable' do
    before do
      job.update(status: :failed)
    end

    it 'contains retry path' do
      expect(subject).to include(:retry_path)
    end
  end

  context 'when job is a regular job' do
    it 'does not contain path to play action' do
      expect(subject).not_to include(:play_path)
    end

    it 'is not a playable job' do
      expect(subject[:playable]).to be false
    end
  end

  context 'when job is a manual action' do
    let(:job) { create(:ci_build, :manual) }

    context 'when user is allowed to trigger action' do
      before do
        project.add_developer(user)

        create(:protected_branch, :developers_can_merge,
               name: 'master', project: project)
      end

      it 'contains path to play action' do
        expect(subject).to include(:play_path)
      end

      it 'is a playable action' do
        expect(subject[:playable]).to be true
      end
    end

    context 'when user is not allowed to trigger action' do
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
      expect(subject[:status]).to include :icon, :favicon, :text, :label
    end
  end
end
