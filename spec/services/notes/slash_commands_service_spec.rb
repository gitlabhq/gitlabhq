require 'spec_helper'

describe Notes::SlashCommandsService, services: true do
  shared_context 'note on noteable' do
    let(:project) { create(:empty_project) }
    let(:master) { create(:user).tap { |u| project.team << [u, :master] } }
    let(:assignee) { create(:user) }
  end

  shared_examples 'note on noteable that does not support slash commands' do
    include_context 'note on noteable'

    before do
      note.note = note_text
    end

    describe 'note with only command' do
      describe '/close, /label, /assign & /milestone' do
        let(:note_text) { %(/close\n/assign @#{assignee.username}") }

        it 'saves the note and does not alter the note text' do
          content, command_params = service.extract_commands(note)

          expect(content).to eq note_text
          expect(command_params).to be_empty
        end
      end
    end

    describe 'note with command & text' do
      describe '/close, /label, /assign & /milestone' do
        let(:note_text) { %(HELLO\n/close\n/assign @#{assignee.username}\nWORLD) }

        it 'saves the note and does not alter the note text' do
          content, command_params = service.extract_commands(note)

          expect(content).to eq note_text
          expect(command_params).to be_empty
        end
      end
    end
  end

  shared_examples 'note on noteable that supports slash commands' do
    include_context 'note on noteable'

    before do
      note.note = note_text
    end

    let!(:milestone) { create(:milestone, project: project) }
    let!(:labels) { create_pair(:label, project: project) }

    describe 'note with only command' do
      describe '/close, /label, /assign & /milestone' do
        let(:note_text) do
          %(/close\n/label ~#{labels.first.name} ~#{labels.last.name}\n/assign @#{assignee.username}\n/milestone %"#{milestone.name}")
        end

        it 'closes noteable, sets labels, assigns, and sets milestone to noteable, and leave no note' do
          content, command_params = service.extract_commands(note)
          service.execute(command_params, note)

          expect(content).to eq ''
          expect(note.noteable).to be_closed
          expect(note.noteable.labels).to match_array(labels)
          expect(note.noteable.assignee).to eq(assignee)
          expect(note.noteable.milestone).to eq(milestone)
        end
      end

      describe '/reopen' do
        before do
          note.noteable.close!
          expect(note.noteable).to be_closed
        end
        let(:note_text) { '/reopen' }

        it 'opens the noteable, and leave no note' do
          content, command_params = service.extract_commands(note)
          service.execute(command_params, note)

          expect(content).to eq ''
          expect(note.noteable).to be_open
        end
      end
    end

    describe 'note with command & text' do
      describe '/close, /label, /assign & /milestone' do
        let(:note_text) do
          %(HELLO\n/close\n/label ~#{labels.first.name} ~#{labels.last.name}\n/assign @#{assignee.username}\n/milestone %"#{milestone.name}"\nWORLD)
        end

        it 'closes noteable, sets labels, assigns, and sets milestone to noteable' do
          content, command_params = service.extract_commands(note)
          service.execute(command_params, note)

          expect(content).to eq "HELLO\nWORLD"
          expect(note.noteable).to be_closed
          expect(note.noteable.labels).to match_array(labels)
          expect(note.noteable.assignee).to eq(assignee)
          expect(note.noteable.milestone).to eq(milestone)
        end
      end

      describe '/reopen' do
        before do
          note.noteable.close
          expect(note.noteable).to be_closed
        end
        let(:note_text) { "HELLO\n/reopen\nWORLD" }

        it 'opens the noteable' do
          content, command_params = service.extract_commands(note)
          service.execute(command_params, note)

          expect(content).to eq "HELLO\nWORLD"
          expect(note.noteable).to be_open
        end
      end
    end
  end

  describe '#execute' do
    let(:service) { described_class.new(project, master) }

    it_behaves_like 'note on noteable that supports slash commands' do
      let(:note) { build(:note_on_issue, project: project) }
    end

    it_behaves_like 'note on noteable that supports slash commands' do
      let(:note) { build(:note_on_merge_request, project: project) }
    end

    it_behaves_like 'note on noteable that does not support slash commands' do
      let(:note) { build(:note_on_commit, project: project) }
    end
  end
end
