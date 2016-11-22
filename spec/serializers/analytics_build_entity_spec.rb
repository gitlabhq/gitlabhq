require 'spec_helper'

describe AnalyticsBuildEntity do
  let(:entity) do
    described_class.new(build, request: double)
  end

  context 'build with an author' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, author: user, started_at: 2.hours.ago, finished_at: 1.hour.ago) }

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

    it 'contains the right started at' do
      expect(subject[:date]).to eq('about 2 hours ago')
    end

    it 'contains the duration' do
      expect(subject[:total_time]).to eq(hours: 1 )
    end
  end
end
