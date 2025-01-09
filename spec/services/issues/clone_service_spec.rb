# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CloneService, feature_category: :team_planning do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:title) { 'Some issue' }
  let_it_be(:description) { "Some issue description with mention to #{user.to_reference}" }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:sub_group_1) { create(:group, :private, parent: group) }
  let_it_be(:sub_group_2) { create(:group, :private, parent: group) }
  let_it_be(:old_project) { create(:project, namespace: sub_group_1) }
  let_it_be(:new_project) { create(:project, namespace: sub_group_2) }

  let_it_be(:old_issue, reload: true) do
    create(:issue, title: title, description: description, project: old_project, author: author, imported_from: :gitlab_migration)
  end

  let(:with_notes) { false }

  subject(:clone_service) do
    described_class.new(container: old_project, current_user: user)
  end

  shared_context 'user can clone issue' do
    before do
      old_project.add_reporter(user)
      new_project.add_reporter(user)
    end
  end

  describe '#execute' do
    context 'issue movable' do
      include_context 'user can clone issue'

      context 'when issue creation fails' do
        before do
          allow_next_instance_of(Issues::CreateService) do |create_service|
            allow(create_service).to receive(:execute).and_return(ServiceResponse.error(message: 'some error'))
          end
        end

        it 'raises a clone error' do
          expect { clone_service.execute(old_issue, new_project) }.to raise_error(
            Issues::CloneService::CloneError,
            'some error'
          )
        end
      end

      # We will use this service in order to clone WorkItem to a new project. As WorkItem inherits from Issue, there
      # should not be any problem with passing a WorkItem instead of an Issue to this service.
      # Adding a small test case to cover this.
      context "when we pass a work_item" do
        include_context 'user can clone issue'

        subject(:clone) { clone_service.execute(original_work_item, new_project) }

        context "work item is of issue type" do
          let_it_be_with_reload(:original_work_item) { create(:work_item, :issue, project: old_project, author: author) }

          it { expect { clone }.to change { new_project.issues.count }.by(1) }
        end

        context "work item is of task type" do
          let_it_be_with_reload(:original_work_item) { create(:work_item, :task, project: old_project, author: author) }

          it { expect { clone }.to raise_error(described_class::CloneError) }
        end
      end

      context 'generic issue' do
        let!(:new_issue) { clone_service.execute(old_issue, new_project, with_notes: with_notes) }

        it 'creates a new issue in the selected project' do
          expect do
            clone_service.execute(old_issue, new_project)
          end.to change { new_project.issues.count }.by(1)
        end

        it 'copies issue title' do
          expect(new_issue.title).to eq title
        end

        it 'copies issue description' do
          expect(new_issue.description).to eq description
        end

        it 'restores imported_from to none' do
          expect(old_issue.reload.imported_from).to eq 'gitlab_migration'
          expect(new_issue.imported_from).to eq 'none'
        end

        it 'adds system note to old issue at the end' do
          expect(old_issue.notes.last.note).to start_with 'cloned to'
        end

        it 'adds system note to new issue at the start' do
          # We set an assignee so an assignee system note will be generated and
          # we can assert that the "cloned from" note is the first one
          assignee = create(:user)
          new_project.add_developer(assignee)
          old_issue.assignees = [assignee]

          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.notes.size).to eq(2)

          cloned_from_note = new_issue.notes.last
          expect(cloned_from_note.note).to start_with 'cloned from'
          expect(new_issue.notes.fresh.first).to eq(cloned_from_note)
        end

        it 'keeps old issue open' do
          expect(old_issue.open?).to be true
        end

        it 'persists new issue' do
          expect(new_issue.persisted?).to be true
        end

        it 'persists all changes' do
          expect(old_issue.changed?).to be false
          expect(new_issue.changed?).to be false
        end

        it 'sets the current user as author' do
          expect(new_issue.author).to eq user
        end

        it 'creates a new internal id for issue' do
          expect(new_issue.iid).to be_present
        end

        it 'sets created_at of new issue to the time of clone' do
          future_time = 5.days.from_now

          travel_to(future_time) do
            new_issue = clone_service.execute(old_issue, new_project, with_notes: with_notes)

            expect(new_issue.created_at).to be_like_time(future_time)
          end
        end

        it 'does not set moved_issue' do
          expect(old_issue.moved?).to eq(false)
        end

        context 'when copying comments' do
          let(:with_notes) { true }

          it 'does not create extra system notes' do
            new_issue = clone_service.execute(old_issue, new_project, with_notes: with_notes)

            expect(new_issue.notes.count).to eq(old_issue.notes.count)
          end
        end
      end

      context 'issue with system notes and resource events' do
        before do
          create(:note, :system, noteable: old_issue, project: old_project)
          create(:resource_label_event, label: create(:label, project: old_project), issue: old_issue)
          create(:resource_state_event, issue: old_issue, state: :reopened)
          create(:resource_milestone_event, issue: old_issue, action: 'remove', milestone_id: nil)
        end

        it 'does not copy system notes and resource events' do
          new_issue = clone_service.execute(old_issue, new_project)

          # 1 here is for the "cloned from" system note
          expect(new_issue.notes.count).to eq(1)
          expect(new_issue.resource_state_events).to be_empty
          expect(new_issue.resource_milestone_events).to be_empty
        end
      end

      context 'issue with award emoji' do
        let!(:award_emoji) { create(:award_emoji, awardable: old_issue) }

        it 'does not copy the award emoji' do
          old_issue.reload
          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.reload.award_emoji).to be_empty
        end
      end

      context 'issue with milestone' do
        let(:milestone) { create(:milestone, group: sub_group_1) }
        let(:new_project) { create(:project, namespace: sub_group_1) }

        let(:old_issue) do
          create(:issue, title: title, description: description, project: old_project, author: author, milestone: milestone)
        end

        it 'copies the milestone and creates a resource_milestone_event' do
          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.milestone).to eq(milestone)
          expect(new_issue.resource_milestone_events.count).to eq(1)
        end
      end

      context 'issue with label' do
        let(:label) { create(:group_label, group: sub_group_1) }
        let(:new_project) { create(:project, namespace: sub_group_1) }

        let(:old_issue) do
          create(:issue, project: old_project, labels: [label])
        end

        it 'copies the label and creates a resource_label_event' do
          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.labels).to contain_exactly(label)
          expect(new_issue.resource_label_events.count).to eq(1)
        end
      end

      context 'issue with due date' do
        let(:date) { Date.parse('2020-01-10') }
        let(:new_date) { date + 1.week }

        let(:old_issue) do
          create(:issue, title: title, description: description, project: old_project, author: author, due_date: date)
        end

        before do
          old_issue.update!(due_date: new_date)
          SystemNoteService.change_start_date_or_due_date(old_issue, old_project, author, old_issue.previous_changes.slice('due_date'))
        end

        it 'keeps the same due date' do
          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.due_date).to eq(old_issue.due_date)
        end
      end

      context 'issue with assignee' do
        let_it_be(:assignee) { create(:user) }

        before do
          old_issue.assignees = [assignee]
        end

        it 'preserves assignee with access to the new issue' do
          new_project.add_reporter(assignee)

          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.assignees).to eq([assignee])
        end

        it 'ignores assignee without access to the new issue' do
          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.assignees).to be_empty
        end
      end

      context 'issue is confidential' do
        before do
          old_issue.update_columns(confidential: true)
        end

        it 'preserves the confidential flag' do
          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.confidential).to be true
        end
      end

      context 'moving to same project' do
        it 'also works' do
          new_issue = clone_service.execute(old_issue, old_project)

          expect(new_issue.project).to eq(old_project)
          expect(new_issue.iid).not_to eq(old_issue.iid)
        end
      end

      context 'project issue hooks' do
        let!(:hook) { create(:project_hook, project: old_project, issues_events: true) }

        it 'executes project issue hooks' do
          allow_next_instance_of(WebHookService) do |instance|
            allow(instance).to receive(:execute)
          end

          # Ideally, we'd test that `WebHookWorker.jobs.size` increased by 1,
          # but since the entire spec run takes place in a transaction, we never
          # actually get to the `after_commit` hook that queues these jobs.
          expect { clone_service.execute(old_issue, new_project) }
          .not_to raise_error # Sidekiq::Worker::EnqueueFromTransactionError
        end
      end

      # These tests verify that notes are copied. More thorough tests are in
      # the unit test for Notes::CopyService.
      context 'issue with notes' do
        let_it_be(:notes) do
          [
            create(:note, noteable: old_issue, project: old_project, created_at: 2.weeks.ago, updated_at: 1.week.ago),
            create(:note, noteable: old_issue, project: old_project)
          ]
        end

        let(:new_issue) { clone_service.execute(old_issue, new_project, with_notes: with_notes) }

        let(:copied_notes) { new_issue.notes.limit(notes.size) } # Remove the system note added by the copy itself

        it 'does not copy notes' do
          # only the system note
          expect(copied_notes.order('id ASC').pluck(:note).size).to eq(1)
        end

        context 'when copying comments' do
          let(:with_notes) { true }

          it 'copies existing notes in order' do
            expect(copied_notes.order('id ASC').pluck(:note)).to eq(notes.map(&:note))
          end
        end
      end

      context 'issue with a design', :clean_gitlab_redis_shared_state do
        let_it_be(:new_project) { create(:project) }

        let!(:design) { create(:design, :with_lfs_file, issue: old_issue) }
        let!(:note) { create(:diff_note_on_design, noteable: design, issue: old_issue, project: old_issue.project) }
        let(:subject) { clone_service.execute(old_issue, new_project) }

        before do
          enable_design_management
        end

        it 'calls CopyDesignCollection::QueueService' do
          expect(DesignManagement::CopyDesignCollection::QueueService).to receive(:new)
                                                                            .with(user, old_issue, kind_of(Issue))
                                                                            .and_call_original

          subject
        end

        it 'logs if QueueService returns an error', :aggregate_failures do
          error_message = 'error'

          expect_next_instance_of(DesignManagement::CopyDesignCollection::QueueService) do |service|
            expect(service).to receive(:execute).and_return(
              ServiceResponse.error(message: error_message)
            )
          end
          expect(Gitlab::AppLogger).to receive(:error).with(error_message)

          subject
        end

        # Perform a small integration test to ensure the services and worker
        # can correctly create designs.
        it 'copies the design and its notes', :sidekiq_inline, :aggregate_failures do
          new_issue = subject

          expect(new_issue.designs.size).to eq(1)
          expect(new_issue.designs.first.notes.size).to eq(1)
        end
      end

      context 'issue relative position' do
        let(:subject) { clone_service.execute(old_issue, new_project) }

        it_behaves_like 'copy or reset relative position'
      end
    end

    describe 'clone permissions' do
      let(:clone) { clone_service.execute(old_issue, new_project) }

      context 'target project is pending deletion' do
        include_context 'user can clone issue'

        before do
          new_project.update_columns(pending_delete: true)
        end

        after do
          new_project.update_columns(pending_delete: false)
        end

        it { expect { clone }.to raise_error(Issues::CloneService::CloneError, /pending deletion/) }
      end

      context 'user is reporter in both projects' do
        include_context 'user can clone issue'
        it { expect { clone }.not_to raise_error }
      end

      context 'user is reporter only in new project' do
        before do
          new_project.add_reporter(user)
        end

        it { expect { clone }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter only in old project' do
        before do
          old_project.add_reporter(user)
        end

        it { expect { clone }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter in one project and guest in another' do
        before do
          new_project.add_guest(user)
          old_project.add_reporter(user)
        end

        it { expect { clone }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue is not persisted' do
        include_context 'user can clone issue'
        let(:old_issue) { build(:issue, project: old_project, author: author) }

        it { expect { clone }.to raise_error(StandardError, /permissions/) }
      end
    end
  end
end
