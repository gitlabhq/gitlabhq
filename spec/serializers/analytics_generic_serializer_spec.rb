require 'spec_helper'

describe AnalyticsGenericSerializer do
  let(:serializer) do
    described_class
      .new(project: project, entity: :merge_request)
      .represent(resource)
  end

  let(:user) { create(:user) }
  let(:json) { serializer.as_json }
  let(:project) { create(:project) }
  let(:resource) {
    {
      total_time: "172802.724419",
      title: "Eos voluptatem inventore in sed.",
      iid: "1",
      id: "1",
      created_at: "2016-11-12 15:04:02.948604",
      author: user,
    }
  }

  context 'when there is a single object provided' do
    it 'it generates payload for single object' do
      expect(json).to be_an_instance_of Hash
    end

    it 'contains important elements of analyticsBuild' do
      expect(json).to include(:title, :iid, :date, :total_time, :url, :author)
    end
  end
end
