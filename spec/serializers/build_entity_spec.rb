require 'spec_helper'

describe BuildEntity do
  let(:user) { create(:user) }
  let(:build) { create(:ci_build) }
  let(:request) { double('request') }

  before do
    allow(request).to receive(:user).and_return(user)
  end

  let(:entity) do
    described_class.new(build, request: request)
  end

  subject { entity.as_json }

  it 'contains paths to build page and retry action' do
    expect(subject).to include(:build_path, :retry_path)
  end

  it 'does not contain sensitive information' do
    expect(subject).not_to include(/token/)
    expect(subject).not_to include(/variables/)
  end

  it 'contains whether it is playable' do
    expect(subject[:playable]).to eq build.playable?
  end

  it 'contains timestamps' do
    expect(subject).to include(:created_at, :updated_at)
  end

  it 'contains details' do
    expect(subject).to include :status
    expect(subject[:status]).to include :icon, :favicon, :text, :label
  end

  context 'when build is a regular job' do
    it 'does not contain path to play action' do
      expect(subject).not_to include(:play_path)
    end

    it 'is not a playable job' do
      expect(subject[:playable]).to be false
    end
  end

  context 'when build is a manual action' do
    let(:build) { create(:ci_build, :manual) }

    context 'when user is allowed to trigger action' do
      before do
        build.project.add_master(user)
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
end
