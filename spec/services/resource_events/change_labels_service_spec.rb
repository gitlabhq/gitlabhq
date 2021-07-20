# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::ChangeLabelsService do
  let_it_be(:project) { create(:project) }
  let_it_be(:author)  { create(:user) }

  let(:resource) { create(:issue, project: project) }

  describe '.change_labels' do
    subject { described_class.new(resource, author).execute(added_labels: added, removed_labels: removed) }

    let_it_be(:labels) { create_list(:label, 2, project: project) }

    def expect_label_event(event, label, action)
      expect(event.user).to eq(author)
      expect(event.label).to eq(label)
      expect(event.action).to eq(action)
    end

    it 'expires resource note etag cache' do
      expect_any_instance_of(Gitlab::EtagCaching::Store)
        .to receive(:touch)
        .with("/#{resource.project.namespace.to_param}/#{resource.project.to_param}/noteable/issue/#{resource.id}/notes")

      described_class.new(resource, author).execute(added_labels: [labels[0]])
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

    describe 'usage data' do
      let(:added)   { [labels[0]] }
      let(:removed) { [labels[1]] }

      context 'when resource is an issue' do
        it 'tracks changed labels' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_label_changed_action)

          subject
        end
      end

      context 'when resource is a merge request' do
        let(:resource) { create(:merge_request, source_project: project) }

        it 'does not track changed labels' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_label_changed_action)

          subject
        end
      end
    end
  end
end
