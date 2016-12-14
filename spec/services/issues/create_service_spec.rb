require 'spec_helper'

describe Issues::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  describe '#execute' do
    let(:issue) { described_class.new(project, user, opts).execute }

    context 'when params are valid' do
      let(:assignee) { create(:user) }
      let(:milestone) { create(:milestone, project: project) }
      let(:labels) { create_pair(:label, project: project) }

      before do
        project.team << [user, :master]
        project.team << [assignee, :master]
      end

      let(:opts) do
        { title: 'Awesome issue',
          description: 'please fix',
          assignee_id: assignee.id,
          label_ids: labels.map(&:id),
          milestone_id: milestone.id,
          due_date: Date.tomorrow }
      end

      it 'creates the issue with the given params' do
        expect(issue).to be_persisted
        expect(issue.title).to eq('Awesome issue')
        expect(issue.assignee).to eq assignee
        expect(issue.labels).to match_array labels
        expect(issue.milestone).to eq milestone
        expect(issue.due_date).to eq Date.tomorrow
      end

      context 'when current user cannot admin issues in the project' do
        let(:guest) { create(:user) }
        before do
          project.team << [guest, :guest]
        end

        it 'filters out params that cannot be set without the :admin_issue permission' do
          issue = described_class.new(project, guest, opts).execute

          expect(issue).to be_persisted
          expect(issue.title).to eq('Awesome issue')
          expect(issue.assignee).to be_nil
          expect(issue.labels).to be_empty
          expect(issue.milestone).to be_nil
          expect(issue.due_date).to be_nil
        end
      end

      it 'creates a pending todo for new assignee' do
        attributes = {
          project: project,
          author: user,
          user: assignee,
          target_id: issue.id,
          target_type: issue.class.name,
          action: Todo::ASSIGNED,
          state: :pending
        }

        expect(Todo.where(attributes).count).to eq 1
      end

      context 'when label belongs to project group' do
        let(:group) { create(:group) }
        let(:group_labels) { create_pair(:group_label, group: group) }

        let(:opts) do
          {
            title: 'Title',
            description: 'Description',
            label_ids: group_labels.map(&:id)
          }
        end

        before do
          project.update(group: group)
        end

        it 'assigns group labels' do
          expect(issue.labels).to match_array group_labels
        end
      end

      context 'when label belongs to different project' do
        let(:label) { create(:label) }

        let(:opts) do
          { title: 'Title',
            description: 'Description',
            label_ids: [label.id] }
        end

        it 'does not assign label' do
          expect(issue.labels).not_to include label
        end
      end

      context 'when milestone belongs to different project' do
        let(:milestone) { create(:milestone) }

        let(:opts) do
          { title: 'Title',
            description: 'Description',
            milestone_id: milestone.id }
        end

        it 'does not assign milestone' do
          expect(issue.milestone).not_to eq milestone
        end
      end

      it 'executes issue hooks when issue is not confidential' do
        opts = { title: 'Title', description: 'Description', confidential: false }

        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :issue_hooks)

        described_class.new(project, user, opts).execute
      end

      it 'executes confidential issue hooks when issue is confidential' do
        opts = { title: 'Title', description: 'Description', confidential: true }

        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :confidential_issue_hooks)

        described_class.new(project, user, opts).execute
      end
    end

    it_behaves_like 'issuable create service'

    it_behaves_like 'new issuable record that supports slash commands'

    context 'for a merge request' do
      let(:discussion) { Discussion.for_diff_notes([create(:diff_note_on_merge_request)]).first }
      let(:merge_request) { discussion.noteable }
      let(:project) { merge_request.source_project }
      let(:opts) { { merge_request_for_resolving_discussions: merge_request } }

      before do
        project.team << [user, :master]
      end

      it 'resolves the discussion for the merge request' do
        described_class.new(project, user, opts).execute
        discussion.first_note.reload

        expect(discussion.resolved?).to be(true)
      end

      it 'added a system note to the discussion' do
        described_class.new(project, user, opts).execute

        reloaded_discussion = MergeRequest.find(merge_request.id).discussions.first

        expect(reloaded_discussion.last_note.system).to eq(true)
      end

      it 'assigns the title and description for the issue' do
        issue = described_class.new(project, user, opts).execute

        expect(issue.title).not_to be_nil
        expect(issue.description).not_to be_nil
      end

      it 'can set nil explicityly to the title and description' do
        issue = described_class.new(project, user,
                                    merge_request_for_resolving_discussions: merge_request,
                                    description: nil,
                                    title: nil).execute

        expect(issue.description).to be_nil
        expect(issue.title).to be_nil
      end
    end
  end
end
