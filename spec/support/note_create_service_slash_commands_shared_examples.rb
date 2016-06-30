# Specifications for behavior common to all note objects with executable attributes.
# It expects a `noteable` object for which the note is posted.

shared_context 'note on noteable' do
  let!(:project) { create(:project) }
  let(:user) { create(:user).tap { |u| project.team << [u, :master] } }
  let(:assignee) { create(:user) }
  let(:base_params) { { noteable: noteable } }
  let(:params) { base_params.merge(example_params) }
  let(:note) { described_class.new(project, user, params).execute }
end

shared_examples 'note on noteable that does not support slash commands' do
  include_context 'note on noteable'

  let(:params) { { commit_id: noteable.id, noteable_type: 'Commit' }.merge(example_params) }

  describe 'note with only command' do
    describe '/close, /label, /assign & /milestone' do
      let(:note_text) { %(/close\n/assign @#{assignee.username}") }
      let(:example_params) { { note: note_text } }

      it 'saves the note and does not alter the note text' do
        expect(note).to be_persisted
        expect(note.note).to eq note_text
      end
    end
  end

  describe 'note with command & text' do
    describe '/close, /label, /assign & /milestone' do
      let(:note_text) { %(HELLO\n/close\n/assign @#{assignee.username}\nWORLD) }
      let(:example_params) { { note: note_text } }

      it 'saves the note and does not alter the note text' do
        expect(note).to be_persisted
        expect(note.note).to eq note_text
      end
    end
  end
end

shared_examples 'note on noteable that supports slash commands' do
  include_context 'note on noteable'

  let!(:milestone) { create(:milestone, project: project) }
  let!(:labels) { create_pair(:label, project: project) }

  describe 'note with only command' do
    describe '/close, /label, /assign & /milestone' do
      let(:example_params) do
        {
          note: %(/close\n/label ~#{labels.first.name} ~#{labels.last.name}\n/assign @#{assignee.username}\n/milestone %"#{milestone.name}")
        }
      end

      it 'closes noteable, sets labels, assigns, and sets milestone to noteable, and leave no note' do
        expect(note).not_to be_persisted
        expect(note.note).to eq ''
        expect(noteable).to be_closed
        expect(noteable.labels).to match_array(labels)
        expect(noteable.assignee).to eq(assignee)
        expect(noteable.milestone).to eq(milestone)
      end
    end

    describe '/open' do
      let(:noteable) { create(:issue, project: project, state: :closed) }
      let(:example_params) do
        {
          note: '/open'
        }
      end

      it 'opens the noteable, and leave no note' do
        expect(note).not_to be_persisted
        expect(note.note).to eq ''
        expect(noteable).to be_open
      end
    end
  end

  describe 'note with command & text' do
    describe '/close, /label, /assign & /milestone' do
      let(:example_params) do
        {
          note: %(HELLO\n/close\n/label ~#{labels.first.name} ~#{labels.last.name}\n/assign @#{assignee.username}\n/milestone %"#{milestone.name}"\nWORLD)
        }
      end

      it 'closes noteable, sets labels, assigns, and sets milestone to noteable' do
        expect(note).to be_persisted
        expect(note.note).to eq "HELLO\nWORLD"
        expect(noteable).to be_closed
        expect(noteable.labels).to match_array(labels)
        expect(noteable.assignee).to eq(assignee)
        expect(noteable.milestone).to eq(milestone)
      end
    end

    describe '/open' do
      let(:noteable) { create(:issue, project: project, state: :closed) }
      let(:example_params) do
        {
          note: "HELLO\n/open\nWORLD"
        }
      end

      it 'opens the noteable' do
        expect(note).to be_persisted
        expect(note.note).to eq "HELLO\nWORLD"
        expect(noteable).to be_open
      end
    end
  end
end
