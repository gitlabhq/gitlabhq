require 'spec_helper'

describe MergeRequests::UpdateService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label) }

  let(:merge_request) do
    create(:merge_request, :simple, title: 'Old title',
                                    assignee_id: user3.id,
                                    source_project: project)
  end

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
    project.team << [user3, :developer]
  end

  describe 'execute' do
    def find_note(starting_with)
      @merge_request.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    def update_merge_request(opts)
      @merge_request = MergeRequests::UpdateService.new(project, user, opts).execute(merge_request)
      @merge_request.reload
    end

    context 'valid params' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close',
          label_ids: [label.id],
          target_branch: 'target',
          force_remove_source_branch: '1'
        }
      end

      let(:service) { MergeRequests::UpdateService.new(project, user, opts) }

      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          @merge_request = service.execute(merge_request)
          @merge_request.reload
        end
      end

      it { expect(@merge_request).to be_valid }
      it { expect(@merge_request.title).to eq('New title') }
      it { expect(@merge_request.assignee).to eq(user2) }
      it { expect(@merge_request).to be_closed }
      it { expect(@merge_request.labels.count).to eq(1) }
      it { expect(@merge_request.labels.first.title).to eq(label.name) }
      it { expect(@merge_request.target_branch).to eq('target') }
      it { expect(@merge_request.merge_params['force_remove_source_branch']).to eq('1') }

      it 'executes hooks with update action' do
        expect(service).to have_received(:execute_hooks).
                               with(@merge_request, 'update')
      end

      it 'sends email to user2 about assign of new merge request and email to user3 about merge request unassignment' do
        deliveries = ActionMailer::Base.deliveries
        email = deliveries.last
        recipients = deliveries.last(2).map(&:to).flatten
        expect(recipients).to include(user2.email, user3.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'creates system note about merge_request reassign' do
        note = find_note('assigned to')

        expect(note).not_to be_nil
        expect(note.note).to include "assigned to #{user2.to_reference}"
      end

      it 'creates system note about merge_request label edit' do
        note = find_note('added ~')

        expect(note).not_to be_nil
        expect(note.note).to include "added #{label.to_reference} label"
      end

      it 'creates system note about title change' do
        note = find_note('changed title')

        expect(note).not_to be_nil
        expect(note.note).to eq 'changed title from **{-Old-} title** to **{+New+} title**'
      end

      it 'creates system note about branch change' do
        note = find_note('changed target')

        expect(note).not_to be_nil
        expect(note.note).to eq 'changed target branch from `master` to `target`'
      end

      context 'when not including source branch removal options' do
        before do
          opts.delete(:force_remove_source_branch)
        end

        it 'maintains the original options' do
          update_merge_request(opts)

          expect(@merge_request.merge_params["force_remove_source_branch"]).to eq("1")
        end
      end
    end

    context 'todos' do
      let!(:pending_todo) { create(:todo, :assigned, user: user, project: project, target: merge_request, author: user2) }

      context 'when the title change' do
        before do
          update_merge_request({ title: 'New title' })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end
      end

      context 'when the description change' do
        before do
          update_merge_request({ description: 'Also please fix' })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end
      end

      context 'when is reassigned' do
        before do
          update_merge_request({ assignee: user2 })
        end

        it 'marks previous assignee pending todos as done' do
          expect(pending_todo.reload).to be_done
        end

        it 'creates a pending todo for new assignee' do
          attributes = {
            project: project,
            author: user,
            user: user2,
            target_id: merge_request.id,
            target_type: merge_request.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq 1
        end
      end

      context 'when the milestone change' do
        before do
          update_merge_request({ milestone: create(:milestone) })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end
      end

      context 'when the labels change' do
        before do
          update_merge_request({ label_ids: [label.id] })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end
      end

      context 'when the target branch change' do
        before do
          update_merge_request({ target_branch: 'target' })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end
      end
    end

    context 'when the issue is relabeled' do
      let!(:non_subscriber) { create(:user) }
      let!(:subscriber) { create(:user) { |u| label.toggle_subscription(u, project) } }

      before do
        project.team << [non_subscriber, :developer]
        project.team << [subscriber, :developer]
      end

      it 'sends notifications for subscribers of newly added labels' do
        opts = { label_ids: [label.id] }

        perform_enqueued_jobs do
          @merge_request = MergeRequests::UpdateService.new(project, user, opts).execute(merge_request)
        end

        should_email(subscriber)
        should_not_email(non_subscriber)
      end

      context 'when issue has the `label` label' do
        before { merge_request.labels << label }

        it 'does not send notifications for existing labels' do
          opts = { label_ids: [label.id, label2.id] }

          perform_enqueued_jobs do
            @merge_request = MergeRequests::UpdateService.new(project, user, opts).execute(merge_request)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end

        it 'does not send notifications for removed labels' do
          opts = { label_ids: [label2.id] }

          perform_enqueued_jobs do
            @merge_request = MergeRequests::UpdateService.new(project, user, opts).execute(merge_request)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end
      end
    end

    context 'updating mentions' do
      let(:mentionable) { merge_request }
      include_examples 'updating mentions', MergeRequests::UpdateService
    end

    context 'when MergeRequest has tasks' do
      before { update_merge_request({ description: "- [ ] Task 1\n- [ ] Task 2" }) }

      it { expect(@merge_request.tasks?).to eq(true) }

      context 'when tasks are marked as completed' do
        before { update_merge_request({ description: "- [x] Task 1\n- [X] Task 2" }) }

        it 'creates system note about task status change' do
          note1 = find_note('marked the task **Task 1** as completed')
          note2 = find_note('marked the task **Task 2** as completed')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil
        end
      end

      context 'when tasks are marked as incomplete' do
        before do
          update_merge_request({ description: "- [x] Task 1\n- [X] Task 2" })
          update_merge_request({ description: "- [ ] Task 1\n- [ ] Task 2" })
        end

        it 'creates system note about task status change' do
          note1 = find_note('marked the task **Task 1** as incomplete')
          note2 = find_note('marked the task **Task 2** as incomplete')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil
        end
      end
    end

    context 'while saving references to issues that the updated merge request closes' do
      let(:first_issue) { create(:issue, project: project) }
      let(:second_issue) { create(:issue, project: project) }

      it 'creates a `MergeRequestsClosingIssues` record for each issue' do
        issue_closing_opts = { description: "Closes #{first_issue.to_reference} and #{second_issue.to_reference}" }
        service = described_class.new(project, user, issue_closing_opts)
        allow(service).to receive(:execute_hooks)
        service.execute(merge_request)

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to match_array([first_issue.id, second_issue.id])
      end

      it 'removes `MergeRequestsClosingIssues` records when issues are not closed anymore' do
        opts = {
          title: 'Awesome merge_request',
          description: "Closes #{first_issue.to_reference} and #{second_issue.to_reference}",
          source_branch: 'feature',
          target_branch: 'master',
          force_remove_source_branch: '1'
        }

        merge_request = MergeRequests::CreateService.new(project, user, opts).execute

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to match_array([first_issue.id, second_issue.id])

        service = described_class.new(project, user, description: "not closing any issues")
        allow(service).to receive(:execute_hooks)
        service.execute(merge_request.reload)

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to be_empty
      end
    end
  end
end
