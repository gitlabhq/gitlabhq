require 'spec_helper'

describe AnalyticsMergeRequestSerializer do
  let(:serializer) do
    described_class
      .new(project: project, entity: :merge_request)
      .represent(resource)
  end

  let(:user) { create(:user) }
  let(:json) { serializer.as_json }
  let(:project) { create(:project) }
  let(:resource) do
    {
      total_time: "172802.724419",
      title: "Eos voluptatem inventore in sed.",
      iid: "1",
      id: "1",
      state: 'open',
      created_at: "2016-11-12 15:04:02.948604",
      author: user
    }
  end

  context 'when there is a single object provided' do
    it 'contains important elements of the merge request' do
      expect(json).to include(:title, :iid, :created_at, :total_time, :url, :author, :state)
    end
  end
end
