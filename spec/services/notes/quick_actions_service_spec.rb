# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::QuickActionsService, feature_category: :team_planning do
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

        context 'user cannot relate issues', :sidekiq_inline do
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
      before do
        # reset to 10 minutes before each test
        note.noteable.update!(time_estimate: 600)
      end

      shared_examples 'does not update time_estimate and displays the correct error message' do
        it 'shows validation error message' do
          content = execute(note)

          expect(content).to be_empty
          expect(note.noteable.errors[:time_estimate]).to include('must have a valid format and be greater than or equal to zero.')
          expect(note.noteable.reload.time_estimate).to eq(600)
        end
      end

      context 'when the time estimate is valid' do
        let(:note_text) { '/estimate 1h' }

        it 'adds time estimate to noteable' do
          content = execute(note)

          expect(content).to be_empty
          expect(note.noteable.reload.time_estimate).to eq(3600)
        end
      end

      context 'when the time estimate is 0' do
        let(:note_text) { '/estimate 0' }

        it 'adds time estimate to noteable' do
          content = execute(note)

          expect(content).to be_empty
          expect(note.noteable.reload.time_estimate).to eq(0)
        end
      end

      context 'when the time estimate is invalid' do
        let(:note_text) { '/estimate a' }

        include_examples "does not update time_estimate and displays the correct error message"
      end

      context 'when the time estimate is partially invalid' do
        let(:note_text) { '/estimate 1d 3id' }

        include_examples "does not update time_estimate and displays the correct error message"
      end

      context 'when the time estimate is negative' do
        let(:note_text) { '/estimate -1h' }

        include_examples "does not update time_estimate and displays the correct error message"
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
          issue.update!(work_item_type: WorkItems::Type.default_by_type(:incident))
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
          issue.update!(work_item_type: WorkItems::Type.default_by_type(:incident))
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

    describe '/promote_to' do
      shared_examples 'promotes work item' do |from:, to:|
        it 'leaves the note empty' do
          expect(execute(note)).to be_empty
        end

        it 'promotes to provided type' do
          expect { execute(note) }.to change { noteable.work_item_type.base_type }.from(from).to(to)
        end
      end

      context 'on a task' do
        let_it_be_with_reload(:noteable) { create(:work_item, :task, project: project) }
        let_it_be(:note_text) { '/promote_to Issue' }
        let_it_be(:note) { create(:note, noteable: noteable, project: project, note: note_text) }

        it_behaves_like 'promotes work item', from: 'task', to: 'issue'

        context 'when type name is lower case' do
          let_it_be(:note_text) { '/promote_to issue' }

          it_behaves_like 'promotes work item', from: 'task', to: 'issue'
        end
      end

      context 'on an issue' do
        let_it_be_with_reload(:noteable) { create(:work_item, :issue, project: project) }
        let_it_be(:note_text) { '/promote_to Incident' }
        let_it_be(:note) { create(:note, noteable: noteable, project: project, note: note_text) }

        it_behaves_like 'promotes work item', from: 'issue', to: 'incident'

        context 'when type name is lower case' do
          let_it_be(:note_text) { '/promote_to incident' }

          it_behaves_like 'promotes work item', from: 'issue', to: 'incident'
        end
      end
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

    context 'note on work item that supports quick actions' do
      include_context 'note on noteable'

      let_it_be(:work_item, reload: true) { create(:work_item, project: project) }

      let(:note) { build(:note_on_work_item, project: project, noteable: work_item) }

      let!(:labels) { create_pair(:label, project: project) }

      before do
        note.note = note_text
      end

      describe 'note with only command' do
        describe '/close, /label & /assign' do
          let(:note_text) do
            %(/close\n/label ~#{labels.first.name} ~#{labels.last.name}\n/assign @#{assignee.username}\n)
          end

          it 'closes noteable, sets labels, assigns and leave no note' do
            content = execute(note)

            expect(content).to be_empty
            expect(note.noteable).to be_closed
            expect(note.noteable.labels).to match_array(labels)
            expect(note.noteable.assignees).to eq([assignee])
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
      end

      describe 'note with command & text' do
        describe '/close, /label, /assign' do
          let(:note_text) do
            %(HELLO\n/close\n/label ~#{labels.first.name} ~#{labels.last.name}\n/assign @#{assignee.username}\nWORLD)
          end

          it 'closes noteable, sets labels, assigns, and sets milestone to noteable' do
            content = execute(note)

            expect(content).to eq "HELLO\nWORLD"
            expect(note.noteable).to be_closed
            expect(note.noteable.labels).to match_array(labels)
            expect(note.noteable.assignees).to eq([assignee])
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
    end
  end

  describe '#apply_updates' do
    include_context 'note on noteable'

    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:work_item, reload: true) { create(:work_item, :issue, project: project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:issue_note) { create(:note_on_issue, project: project, noteable: issue) }
    let_it_be(:work_item_note) { create(:note, project: project, noteable: work_item) }
    let_it_be(:mr_note) { create(:note_on_merge_request, project: project, noteable: merge_request) }
    let_it_be(:commit_note) { create(:note_on_commit, project: project) }
    let(:update_params) { {} }

    subject(:apply_updates) { described_class.new(project, maintainer).apply_updates(update_params, note) }

    context 'with a note on an issue' do
      let(:note) { issue_note }

      it 'returns successful service response if update returned no errors' do
        update_params[:confidential] = true
        expect(apply_updates.success?).to be true
      end

      it 'returns service response with errors if update failed' do
        update_params[:title] = ""
        expect(apply_updates.success?).to be false
        expect(apply_updates.message).to include("Title can't be blank")
      end
    end

    context 'with a note on a merge request' do
      let(:note) { mr_note }

      it 'returns successful service response if update returned no errors' do
        update_params[:title] = 'New title'
        expect(apply_updates.success?).to be true
      end

      it 'returns service response with errors if update failed' do
        update_params[:title] = ""
        expect(apply_updates.success?).to be false
        expect(apply_updates.message).to include("Title can't be blank")
      end
    end

    context 'with a note on a work item' do
      let(:note) { work_item_note }

      before do
        update_params[:confidential] = true
      end

      it 'returns successful service response if update returned no errors' do
        expect(apply_updates.success?).to be true
      end

      it 'returns service response with errors if update failed' do
        task = create(:work_item, :task, project: project)
        create(:parent_link, work_item: task, work_item_parent: work_item)

        expect(apply_updates.success?).to be false
        expect(apply_updates.message)
          .to include("A confidential work item cannot have a parent that already has non-confidential children.")
      end
    end

    context 'with a note on a commit' do
      let(:note) { commit_note }

      it 'returns successful service response if update returned no errors' do
        update_params[:tag_name] = 'test'
        expect(apply_updates.success?).to be true
      end

      it 'returns service response with errors if update failed' do
        update_params[:tag_name] = '-test'
        expect(apply_updates.success?).to be false
        expect(apply_updates.message).to include('Tag name invalid')
      end
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
