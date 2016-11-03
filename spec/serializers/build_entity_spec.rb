require 'spec_helper'

describe BuildEntity do
  subject do
    described_class.new(build, request: double).as_json
  end

  context 'when build is a regular job' do
    let(:build) { create(:ci_build) }

    it 'contains url to build page and retry action' do
      expect(subject).to include(:build_url, :retry_url)
      expect(subject).not_to include(:play_url)
    end
  end

  context 'when build is a manual action' do
    let(:build) { create(:ci_build, :manual) }

    it 'contains url to play action' do
      expect(subject).to include(:play_url)
    end
  end
end
