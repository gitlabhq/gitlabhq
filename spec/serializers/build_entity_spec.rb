require 'spec_helper'

describe BuildEntity do
  let(:entity) do
    described_class.new(build, request: double)
  end

  subject { entity.as_json }

  context 'when build is a regular job' do
    let(:build) { create(:ci_build) }

    it 'contains paths to build page and retry action' do
      expect(subject).to include(:build_path, :retry_path)
      expect(subject).not_to include(:play_path)
    end

    it 'does not contain sensitive information' do
      expect(subject).not_to include(/token/)
      expect(subject).not_to include(/variables/)
    end
  end

  context 'when build is a manual action' do
    let(:build) { create(:ci_build, :manual) }

    it 'contains path to play action' do
      expect(subject).to include(:play_path)
    end
  end
end
