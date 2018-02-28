require 'spec_helper'

describe AnalyticsIssueEntity do
  let(:user) { create(:user) }
  let(:entity_hash) do
    {
      total_time: "172802.724419",
      title: "Eos voluptatem inventore in sed.",
      iid: "1",
      id: "1",
      created_at: "2016-11-12 15:04:02.948604",
      author: user
    }
  end

  let(:project) { create(:project) }
  let(:request) { EntityRequest.new(project: project, entity: :merge_request) }

  let(:entity) do
    described_class.new(entity_hash, request: request, project: project)
  end

  context 'generic entity' do
    subject { entity.as_json }

    it 'contains the entity URL' do
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
