# frozen_string_literal: true

require 'spec_helper'

describe Issuable::CommonSystemNotesService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issuable) { create(:issue, project: project) }

  context 'on issuable update' do
    it_behaves_like 'system note creation', { title: 'New title' }, 'changed title'
    it_behaves_like 'system note creation', { description: 'New description' }, 'changed the description'
    it_behaves_like 'system note creation', { discussion_locked: true }, 'locked this issue'
    it_behaves_like 'system note creation', { time_estimate: 5 }, 'changed time estimate'

    context 'when new label is added' do
      let(:label) { create(:label, project: project) }

      before do
        issuable.labels << label
        issuable.save
      end

      it 'creates a resource label event' do
        described_class.new(project, user).execute(issuable, old_labels: [])
        event = issuable.reload.resource_label_events.last

        expect(event).not_to be_nil
        expect(event.label_id).to eq label.id
        expect(event.user_id).to eq user.id
      end
    end

    context 'when new milestone is assigned' do
      before do
        milestone = create(:milestone, project: project)
        issuable.milestone_id = milestone.id
      end

      it_behaves_like 'system note creation', {}, 'changed milestone'
    end

    context 'with merge requests WIP note' do
      context 'adding WIP note' do
        let(:issuable) { create(:merge_request, title: "merge request") }

        it_behaves_like 'system note creation', { title: "WIP merge request" }, 'marked as a **Work In Progress**'

        context 'and changing title' do
          before do
            issuable.update_attribute(:title, "WIP changed title")
          end

          it_behaves_like 'WIP notes creation', 'marked'
        end
      end

      context 'removing WIP note' do
        let(:issuable) { create(:merge_request, title: "WIP merge request") }

        it_behaves_like 'system note creation', { title: "merge request" }, 'unmarked as a **Work In Progress**'

        context 'and changing title' do
          before do
            issuable.update_attribute(:title, "changed title")
          end

          it_behaves_like 'WIP notes creation', 'unmarked'
        end
      end
    end
  end

  context 'on issuable create' do
    let(:issuable) { build(:issue, project: project) }

    subject { described_class.new(project, user).execute(issuable, old_labels: [], is_update: false) }

    it 'does not create system note for title and description' do
      issuable.save

      expect { subject }.not_to change { issuable.notes.count }
    end

    it 'creates a resource label event for labels added' do
      label = create(:label, project: project)

      issuable.labels << label
      issuable.save

      expect { subject }.to change { issuable.resource_label_events.count }.from(0).to(1)

      event = issuable.reload.resource_label_events.last

      expect(event).not_to be_nil
      expect(event.label_id).to eq label.id
      expect(event.user_id).to eq user.id
    end

    it 'creates a system note for milestone set' do
      issuable.milestone = create(:milestone, project: project)
      issuable.save

      expect { subject }.to change { issuable.notes.count }.from(0).to(1)
      expect(issuable.notes.last.note).to match('changed milestone')
    end

    it 'creates a system note for due_date set' do
      issuable.due_date = Date.today
      issuable.save

      expect { subject }.to change { issuable.notes.count }.from(0).to(1)
      expect(issuable.notes.last.note).to match('changed due date')
    end
  end
end
