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
      expect(note.noteable_type).to eq('Issue')
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
  end
end
