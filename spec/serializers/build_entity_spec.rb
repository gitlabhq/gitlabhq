require 'spec_helper'

describe BuildEntity do
  let(:build) { create(:ci_build) }

  let(:entity) do
    described_class.new(build, request: double)
  end

  subject { entity.as_json }

  it 'contains paths to build page and retry action' do
    expect(subject).to include(:build_path, :retry_path)
  end

  it 'does not contain sensitive information' do
    expect(subject).not_to include(/token/)
    expect(subject).not_to include(/variables/)
  end

  it 'contains timestamps' do
    expect(subject).to include(:created_at, :updated_at)
  end

  context 'when build is a regular job' do
    it 'does not contain path to play action' do
      expect(subject).not_to include(:play_path)
    end
  end

  context 'when build is a manual action' do
    let(:build) { create(:ci_build, :manual) }

    it 'contains path to play action' do
      expect(subject).to include(:play_path)
    end
  end
end
