# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::CommonSystemNotesService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:issuable) { create(:issue, project: project) }

  shared_examples 'system note for issuable date changes' do
    it 'does not call SystemNoteService if no dates are changed' do
      issuable.update!(title: 'new title')

      expect(SystemNoteService).not_to receive(:change_start_date_or_due_date)

      execute_notes_service
    end

    context 'and issuable is an Issue' do
      it 'creates a system note for due_date set' do
        issuable.update!(due_date: Date.today)

        expect { execute_notes_service }.to change { issuable.notes.count }.from(0).to(1)
        expect(issuable.notes.last.note).to match('changed due date to')
      end

      it 'creates a system note for start_date set' do
        issuable.update!(start_date: Date.today)

        expect { execute_notes_service }.to change { issuable.notes.count }.from(0).to(1)
        expect(issuable.notes.last.note).to match('changed start date to')
      end

      it 'creates a note when both start and due date are changed' do
        issuable.update!(start_date: Date.today, due_date: 1.week.from_now)

        expect { execute_notes_service }.to change { issuable.notes.count }.from(0).to(1)
        expect(issuable.notes.last.note).to match(/changed start date to.+and changed due date to/)
      end
    end

    context 'and issuable is a WorkItem' do
      let_it_be_with_reload(:issuable) { create(:work_item, :issue, project: project) }
      let(:dates_source) { create(:work_items_dates_source, work_item: issuable) }

      it 'creates a system note for due_date set' do
        dates_source.update!(due_date: Date.today)

        expect { execute_notes_service }.to change { issuable.notes.count }.from(0).to(1)
        expect(issuable.notes.last.note).to match('changed due date to')
      end

      it 'creates a system note for start_date set' do
        dates_source.update!(start_date: Date.today)

        expect { execute_notes_service }.to change { issuable.notes.count }.from(0).to(1)
        expect(issuable.notes.last.note).to match('changed start date to')
      end

      it 'creates a note when both start and due date are changed' do
        dates_source.update!(start_date: Date.today, due_date: 1.week.from_now)

        expect { execute_notes_service }.to change { issuable.notes.count }.from(0).to(1)
        expect(issuable.notes.last.note).to match(/changed start date to.+and changed due date to/)
      end
    end
  end

  context 'on issuable update' do
    it_behaves_like 'system note creation', { title: 'New title' }, 'changed title'
    it_behaves_like 'system note creation', { description: 'New description' }, 'changed the description'
    it_behaves_like 'system note creation', { discussion_locked: true }, 'locked the discussion in this issue'
    it_behaves_like 'system note creation', { time_estimate: 5 }, 'added time estimate of 5s'

    context 'when new label is added' do
      let(:label) { create(:label, project: project) }

      before do
        issuable.labels << label
        issuable.save!
      end

      it 'creates a resource label event' do
        described_class.new(project: project, current_user: user).execute(issuable, old_labels: [])
        event = issuable.reload.resource_label_events.last

        expect(event).not_to be_nil
        expect(event.label_id).to eq label.id
        expect(event.user_id).to eq user.id
      end
    end

    context 'with merge requests Draft note' do
      context 'and adding Draft note' do
        let(:issuable) { create(:merge_request, title: "merge request") }

        it_behaves_like 'system note creation',
          { title: "Draft: merge request" },
          'marked this merge request as **draft**'

        context 'and changing title' do
          before do
            issuable.update_attribute(:title, "Draft: changed title")
          end

          it_behaves_like 'draft notes creation', 'draft'
        end
      end

      context 'and removing Draft note' do
        let(:issuable) { create(:merge_request, title: "Draft: merge request") }

        it_behaves_like 'system note creation', { title: "merge request" }, 'marked this merge request as **ready**'

        context 'and changing title' do
          before do
            issuable.update_attribute(:title, "changed title")
          end

          it_behaves_like 'draft notes creation', 'ready'
        end
      end
    end

    context 'when changing dates' do
      it_behaves_like 'system note for issuable date changes' do
        subject(:execute_notes_service) do
          described_class
            .new(project: project, current_user: user)
            .execute(issuable)
        end
      end
    end
  end

  context 'on issuable create' do
    let(:issuable) { build(:issue, project: project) }

    subject(:execute_notes_service) do
      described_class
        .new(project: project, current_user: user)
        .execute(issuable, old_labels: [], is_update: false)
    end

    it 'does not create system note for title and description' do
      issuable.save!

      expect { subject }.not_to change { issuable.notes.count }
    end

    it 'creates a resource label event for labels added' do
      label = create(:label, project: project)

      issuable.labels << label
      issuable.save!

      expect { subject }.to change { issuable.resource_label_events.count }.from(0).to(1)

      event = issuable.reload.resource_label_events.last

      expect(event).not_to be_nil
      expect(event.label_id).to eq label.id
      expect(event.user_id).to eq user.id
    end

    context 'when changing milestones' do
      let_it_be(:milestone) { create(:milestone, project: project) }
      let_it_be(:issuable) { create(:issue, project: project, milestone: milestone) }

      it 'does not create a system note for milestone set' do
        expect { subject }.not_to change { issuable.notes.count }
      end

      it 'creates a milestone change event' do
        expect { subject }.to change { ResourceMilestoneEvent.count }.from(0).to(1)
      end
    end

    context 'when changing dates' do
      it_behaves_like 'system note for issuable date changes'
    end

    context 'when setting an estimae' do
      it_behaves_like 'system note creation', { time_estimate: 5 }, 'added time estimate of 5s', false
    end
  end
end
