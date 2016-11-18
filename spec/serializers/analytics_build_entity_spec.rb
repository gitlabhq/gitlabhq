require 'spec_helper'

describe AnalyticsBuildEntity do
  let(:entity) do
    described_class.new(build, request: double)
  end

  context 'build with an author' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, author: user) }

    subject { entity.as_json }

    it 'contains the URL' do
      expect(subject).to include(:url)
    end

    it 'contains the author' do
      expect(subject).to include(:author)
    end

    it 'does not contain sensitive information' do
      expect(subject).not_to include(/token/)
      expect(subject).not_to include(/variables/)
    end
  end
end
