require 'spec_helper'

describe Issuable::CommonSystemNotesService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issuable) { create(:issue) }

  shared_examples 'system note creation' do |update_params, note_text|
    subject { described_class.new(project, user).execute(issuable, [])}

    before do
      issuable.assign_attributes(update_params)
      issuable.save
    end

    it 'creates 1 system note with the correct content' do
      expect { subject }.to change { Note.count }.from(0).to(1)

      note = Note.last
      expect(note.note).to match(note_text)
      expect(note.noteable_type).to eq(issuable.class.name)
    end
  end

  shared_examples 'WIP notes creation' do |wip_action|
    subject { described_class.new(project, user).execute(issuable, []) }

    it 'creates WIP toggle and title change notes' do
      expect { subject }.to change { Note.count }.from(0).to(2)

      expect(Note.first.note).to match("#{wip_action} as a **Work In Progress**")
      expect(Note.second.note).to match('changed title')
    end
  end

  describe '#execute' do
    it_behaves_like 'system note creation', { title: 'New title' }, 'changed title'
    it_behaves_like 'system note creation', { description: 'New description' }, 'changed the description'
    it_behaves_like 'system note creation', { discussion_locked: true }, 'locked this issue'
    it_behaves_like 'system note creation', { time_estimate: 5 }, 'changed time estimate'

    context 'when new label is added' do
      before do
        label = create(:label, project: project)
        issuable.labels << label
      end

      it_behaves_like 'system note creation', {}, /added ~\w+ label/
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
end
