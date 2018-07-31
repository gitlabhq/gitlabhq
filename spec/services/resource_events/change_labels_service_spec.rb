# frozen_string_literal: true

require 'spec_helper'

describe ResourceEvents::ChangeLabelsService do
  set(:project)  { create(:project) }
  set(:author)   { create(:user) }
  let(:resource) { create(:issue, project: project) }

  describe '.change_labels' do
    subject { described_class.new(resource, author).execute(added_labels: added, removed_labels: removed) }

    let(:labels)  { create_list(:label, 2, project: project) }

    def expect_label_event(event, label, action)
      expect(event.user).to eq(author)
      expect(event.label).to eq(label)
      expect(event.action).to eq(action)
    end

    context 'when adding a label' do
      let(:added)   { [labels[0]] }
      let(:removed) { [] }

      it 'creates new label event' do
        expect { subject }.to change { resource.resource_label_events.count }.from(0).to(1)

        expect_label_event(resource.resource_label_events.first, labels[0], 'add')
      end
    end

    context 'when removing a label' do
      let(:added)   { [] }
      let(:removed) { [labels[1]] }

      it 'creates new label event' do
        expect { subject }.to change { resource.resource_label_events.count }.from(0).to(1)

        expect_label_event(resource.resource_label_events.first, labels[1], 'remove')
      end
    end

    context 'when both adding and removing labels' do
      let(:added)   { [labels[0]] }
      let(:removed) { [labels[1]] }

      it 'creates all label events in a single query' do
        expect(Gitlab::Database).to receive(:bulk_insert).once.and_call_original
        expect { subject }.to change { resource.resource_label_events.count }.from(0).to(2)
      end
    end
  end
end
