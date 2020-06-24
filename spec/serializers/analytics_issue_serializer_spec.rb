# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AnalyticsIssueSerializer do
  subject do
    described_class
      .new(entity: :merge_request)
      .represent(resource)
  end

  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'my project') }
  let(:resource) do
    {
      total_time: "172802.724419",
      title: "Eos voluptatem inventore in sed.",
      iid: "1",
      id: "1",
      created_at: "2016-11-12 15:04:02.948604",
      author: user,
      project_path: project.path,
      namespace_path: project.namespace.route.path
    }
  end

  context 'when there is a single object provided' do
    it 'contains important elements of the issue' do
      expect(subject).to include(:title, :iid, :created_at, :total_time, :url, :author)
    end
  end
end
