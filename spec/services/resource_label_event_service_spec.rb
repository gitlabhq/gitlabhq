# frozen_string_literal: true

require 'spec_helper'

describe ResourceLabelEventService do
  set(:project)  { create(:project) }
  set(:author)   { create(:user) }
  let(:resource) { create(:issue, project: project) }

  describe '.change_labels' do
    subject { described_class.change_labels(resource, author, added, removed) }

    let(:labels)  { create_list(:label, 2, project: project) }
    let(:added)   { [labels[0]] }
    let(:removed) { [labels[1]] }

    it 'creates an event for each label in single query' do
      expect(Gitlab::Database).to receive(:bulk_insert).once.and_call_original
      expect { subject }.to change { resource.resource_label_events.count }.from(0).to(2)
    end
  end
end
