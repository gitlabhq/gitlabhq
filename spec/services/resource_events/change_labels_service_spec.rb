# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::ChangeLabelsService do
  let_it_be(:project) { create(:project) }
  let_it_be(:author)  { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:incident) { create(:incident, project: project) }

  let(:resource) { issue }

  describe '#execute' do
    shared_examples 'creating timeline events' do
      context 'when resource is not an incident' do
        let(:resource) { issue }

        it 'does not call create timeline events service' do
          expect(IncidentManagement::TimelineEvents::CreateService).not_to receive(:change_labels)

          change_labels
        end
      end

      context 'when resource is an incident' do
        let(:resource) { incident }

        it 'calls create timeline events service with correct attributes' do
          expect(IncidentManagement::TimelineEvents::CreateService)
            .to receive(:change_labels)
            .with(resource, author, added_labels: added, removed_labels: removed)
            .and_call_original

          change_labels
        end
      end
    end

    subject(:change_labels) do
      described_class.new(resource, author).execute(added_labels: added, removed_labels: removed)
    end

    let_it_be(:labels) { create_list(:label, 2, project: project) }

    def expect_label_event(event, label, action)
      expect(event.user).to eq(author)
      expect(event.label).to eq(label)
      expect(event.action).to eq(action)
    end

    it 'expires resource note etag cache' do
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(
        "/#{resource.project.namespace.to_param}/#{resource.project.to_param}/noteable/issue/#{resource.id}/notes"
      )

      described_class.new(resource, author).execute(added_labels: [labels[0]])
    end

    context 'when adding a label' do
      let(:added)   { [labels[0]] }
      let(:removed) { [] }

      it 'creates new label event' do
        expect { change_labels }.to change { resource.resource_label_events.count }.from(0).to(1)

        expect_label_event(resource.resource_label_events.first, labels[0], 'add')
      end

      it_behaves_like 'creating timeline events'
    end

    context 'when removing a label' do
      let(:added)   { [] }
      let(:removed) { [labels[1]] }

      it 'creates new label event' do
        expect { change_labels }.to change { resource.resource_label_events.count }.from(0).to(1)

        expect_label_event(resource.resource_label_events.first, labels[1], 'remove')
      end

      it_behaves_like 'creating timeline events'
    end

    context 'when both adding and removing labels' do
      let(:added)   { [labels[0]] }
      let(:removed) { [labels[1]] }

      it 'creates all label events in a single query' do
        expect(ApplicationRecord).to receive(:legacy_bulk_insert).once.and_call_original
        expect { change_labels }.to change { resource.resource_label_events.count }.from(0).to(2)
      end

      it_behaves_like 'creating timeline events'
    end

    describe 'usage data' do
      let(:added)   { [labels[0]] }
      let(:removed) { [labels[1]] }

      context 'when resource is an issue' do
        it 'tracks changed labels' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_label_changed_action)

          change_labels
        end
      end

      context 'when resource is a merge request' do
        let(:resource) { create(:merge_request, source_project: project) }

        it 'does not track changed labels' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter)
            .not_to receive(:track_issue_label_changed_action)

          change_labels
        end
      end
    end
  end
end
