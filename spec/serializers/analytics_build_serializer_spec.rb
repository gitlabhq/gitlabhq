require 'spec_helper'

describe AnalyticsBuildSerializer do
  let(:serializer) do
    described_class
      .new.represent(resource)
  end

  let(:json) { serializer.as_json }
  let(:resource) { create(:ci_build) }

  context 'when there is a single object provided' do
    it 'it generates payload for single object' do
      expect(json).to be_an_instance_of Hash
    end

    it 'contains important elements of analyticsBuild' do
      expect(json)
        .to include(:name, :branch, :short_sha, :date, :total_time, :url, :author)
    end
  end
end
