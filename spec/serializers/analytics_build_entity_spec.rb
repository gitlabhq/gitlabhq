require 'spec_helper'

describe AnalyticsBuildEntity do
  let(:entity) do
    described_class.new(build, request: double)
  end

  context 'when build is a regular job' do
    let(:build) { create(:ci_build) }

    subject { entity.as_json }

    it 'contains url to build page and retry action' do
      expect(subject).to include(:url, :branch_url, :commit_url)
    end

    it 'does not contain sensitive information' do
      expect(subject).not_to include(/token/)
      expect(subject).not_to include(/variables/)
    end
  end
end
