# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::QuickActionsService do
  shared_context 'note on noteable' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:maintainer) { create(:user).tap { |u| project.add_maintainer(u) } }
    let_it_be(:assignee) { create(:user) }

    before do
      project.add_maintainer(assignee)
    end
  end

  shared_examples 'note on noteable that supports quick actions' do
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
          content = execute(note)

          expect(content).to be_empty
          expect(note.noteable).to be_closed
          expect(note.noteable.labels).to match_array(labels)
          expect(note.noteable.assignees).to eq([assignee])
          expect(note.noteable.milestone).to eq(milestone)
        end
      end

      context '/relate' do
        let_it_be(:issue) { create(:issue, project: project) }
        let_it_be(:other_issue) { create(:issue, project: project) }

        let(:note_text) { "/relate #{other_issue.to_reference}" }
        let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

        context 'user cannot relate issues' do
          before do
            project.team.find_member(maintainer.id).destroy!
            project.update!(visibility: Gitlab::VisibilityLevel::PUBLIC)
          end

          it 'does not create issue relation' do
            expect { execute(note) }.not_to change { IssueLink.count }
          end
        end

        context 'user is allowed to relate issues' do
          it 'creates issue relation' do
            expect { execute(note) }.to change { IssueLink.count }.by(1)
          end
        end
      end

      describe '/reopen' do
        before do
          note.noteable.close!
          expect(note.noteable).to be_closed
        end
        let(:note_text) { '/reopen' }

        it 'opens the noteable, and leave no note' do
          content = execute(note)

          expect(content).to be_empty
          expect(note.noteable).to be_open
        end
      end

      describe '/spend' do
        context 'when note is not persisted' do
          let(:note_text) { '/spend 1h' }

          it 'adds time to noteable, adds timelog with nil note_id and has no content' do
            content = execute(note)

            expect(content).to be_empty
            expect(note.noteable.time_spent).to eq(3600)
            expect(Timelog.last.note_id).to be_nil
          end
        end

        context 'when note is persisted' do
          let(:note_text) { "a note \n/spend 1h" }

          it 'updates the spent time and populates timelog with note_id' do
            new_content, update_params = service.execute(note)
            note.update!(note: new_content)
            service.apply_updates(update_params, note)

            expect(Timelog.last.note_id).to eq(note.id)
          end
        end

        context 'adds a system note' do
          context 'when not specifying a date' do
            let(:note_text) { "/spend 1h" }

            it 'does not include the date' do
              _, update_params = service.execute(note)
              service.apply_updates(update_params, note)

              expect(Note.last.note).to eq('added 1h of time spent')
            end
          end

          context 'when specifying a date' do
            let(:note_text) { "/spend 1h 2020-01-01" }

            it 'does include the date' do
              _, update_params = service.execute(note)
              service.apply_updates(update_params, note)

              expect(Note.last.note).to eq('added 1h of time spent at 2020-01-01')
            end
          end
        end
      end
    end

    describe '/estimate' do
      let(:note_text) { '/estimate 1h' }

      it 'adds time estimate to noteable' do
        content = execute(note)

        expect(content).to be_empty
        expect(note.noteable.time_estimate).to eq(3600)
      end
    end

    describe 'note with command & text' do
      describe '/close, /label, /assign & /milestone' do
        let(:note_text) do
          %(HELLO\n/close\n/label ~#{labels.first.name} ~#{labels.last.name}\n/assign @#{assignee.username}\n/milestone %"#{milestone.name}"\nWORLD)
        end

        it 'closes noteable, sets labels, assigns, and sets milestone to noteable' do
          content = execute(note)

          expect(content).to eq "HELLO\nWORLD"
          expect(note.noteable).to be_closed
          expect(note.noteable.labels).to match_array(labels)
          expect(note.noteable.assignees).to eq([assignee])
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
          content = execute(note)

          expect(content).to eq "HELLO\nWORLD"
          expect(note.noteable).to be_open
        end
      end
    end

    describe '/milestone' do
      let(:issue) { create(:issue, project: project) }
      let(:note_text) { %(/milestone %"#{milestone.name}") }
      let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

      context 'on an incident' do
        before do
          issue.update!(issue_type: :incident)
        end

        it 'leaves the note empty' do
          expect(execute(note)).to be_empty
        end

        it 'assigns the milestone' do
          expect { execute(note) }.to change { issue.reload.milestone }.from(nil).to(milestone)
        end
      end

      context 'on a merge request' do
        let(:note_mr) { create(:note_on_merge_request, project: project, note: note_text) }

        it 'leaves the note empty' do
          expect(execute(note_mr)).to be_empty
        end

        it 'assigns the milestone' do
          expect { execute(note) }.to change { issue.reload.milestone }.from(nil).to(milestone)
        end
      end
    end

    describe '/remove_milestone' do
      let(:issue) { create(:issue, project: project, milestone: milestone) }
      let(:note_text) { '/remove_milestone' }
      let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

      context 'on an issue' do
        it 'leaves the note empty' do
          expect(execute(note)).to be_empty
        end

        it 'removes the milestone' do
          expect { execute(note) }.to change { issue.reload.milestone }.from(milestone).to(nil)
        end
      end

      context 'on an incident' do
        before do
          issue.update!(issue_type: :incident)
        end

        it 'leaves the note empty' do
          expect(execute(note)).to be_empty
        end

        it 'removes the milestone' do
          expect { execute(note) }.to change { issue.reload.milestone }.from(milestone).to(nil)
        end
      end

      context 'on a merge request' do
        let(:note_mr) { create(:note_on_merge_request, project: project, note: note_text) }

        it 'leaves the note empty' do
          expect(execute(note_mr)).to be_empty
        end

        it 'removes the milestone' do
          expect { execute(note) }.to change { issue.reload.milestone }.from(milestone).to(nil)
        end
      end
    end
  end

  describe '.noteable_update_service_class' do
    include_context 'note on noteable'

    it 'returns Issues::UpdateService for a note on an issue' do
      note = create(:note_on_issue, project: project)

      expect(described_class.noteable_update_service_class(note)).to eq(Issues::UpdateService)
    end

    it 'returns MergeRequests::UpdateService for a note on a merge request' do
      note = create(:note_on_merge_request, project: project)

      expect(described_class.noteable_update_service_class(note)).to eq(MergeRequests::UpdateService)
    end

    it 'returns Commits::TagService for a note on a commit' do
      note = create(:note_on_commit, project: project)

      expect(described_class.noteable_update_service_class(note)).to eq(Commits::TagService)
    end
  end

  describe '.supported?' do
    include_context 'note on noteable'

    let(:note) { create(:note_on_issue, project: project) }

    context 'with a note on an issue' do
      it 'returns true' do
        expect(described_class.supported?(note)).to be_truthy
      end
    end

    context 'with a note on a commit' do
      let(:note) { create(:note_on_commit, project: project) }

      it 'returns false' do
        expect(described_class.supported?(note)).to be_truthy
      end
    end
  end

  describe '#supported?' do
    include_context 'note on noteable'

    it 'delegates to the class method' do
      service = described_class.new(project, maintainer)
      note = create(:note_on_issue, project: project)

      expect(described_class).to receive(:supported?).with(note)

      service.supported?(note)
    end
  end

  describe '#execute' do
    let(:service) { described_class.new(project, maintainer) }

    it_behaves_like 'note on noteable that supports quick actions' do
      let_it_be(:issue, reload: true) { create(:issue, project: project) }
      let(:note) { build(:note_on_issue, project: project, noteable: issue) }
    end

    it_behaves_like 'note on noteable that supports quick actions' do
      let_it_be(:incident, reload: true) { create(:incident, project: project) }
      let(:note) { build(:note_on_issue, project: project, noteable: incident) }
    end

    it_behaves_like 'note on noteable that supports quick actions' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:note) { build(:note_on_merge_request, project: project, noteable: merge_request) }
    end
  end

  context 'CE restriction for issue assignees' do
    describe '/assign' do
      let(:project) { create(:project) }
      let(:assignee) { create(:user) }
      let(:maintainer) { create(:user) }
      let(:service) { described_class.new(project, maintainer) }
      let(:note) { create(:note_on_issue, note: note_text, project: project) }

      let(:note_text) do
        %(/assign @#{assignee.username} @#{maintainer.username}\n")
      end

      before do
        stub_licensed_features(multiple_issue_assignees: false)
        project.add_maintainer(maintainer)
        project.add_maintainer(assignee)
      end

      it 'adds only one assignee from the list' do
        execute(note)

        expect(note.noteable.assignees.count).to eq(1)
      end
    end
  end

  def execute(note)
    content, update_params = service.execute(note)
    service.apply_updates(update_params, note)

    content
  end
end
