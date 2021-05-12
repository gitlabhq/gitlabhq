# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CloneService do
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
    create(:issue, title: title, description: description, project: old_project, author: author)
  end

  let(:with_notes) { false }

  subject(:clone_service) do
    described_class.new(project: old_project, current_user: user)
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

        it 'adds system note to old issue at the end' do
          expect(old_issue.notes.last.note).to start_with 'cloned to'
        end

        it 'adds system note to new issue at the end' do
          expect(new_issue.notes.last.note).to start_with 'cloned from'
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

        it 'preserves create time' do
          expect(old_issue.created_at.strftime('%D')).to eq new_issue.created_at.strftime('%D')
        end

        it 'does not copy system notes' do
          expect(new_issue.notes.count).to eq(1)
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

      context 'issue with award emoji' do
        let!(:award_emoji) { create(:award_emoji, awardable: old_issue) }

        it 'copies the award emoji' do
          old_issue.reload
          new_issue = clone_service.execute(old_issue, new_project)

          expect(old_issue.award_emoji.first.name).to eq new_issue.reload.award_emoji.first.name
        end
      end

      context 'issue with milestone' do
        let(:milestone) { create(:milestone, group: sub_group_1) }
        let(:new_project) { create(:project, namespace: sub_group_1) }

        let(:old_issue) do
          create(:issue, title: title, description: description, project: old_project, author: author, milestone: milestone)
        end

        before do
          create(:resource_milestone_event, issue: old_issue, milestone: milestone, action: :add)
        end

        it 'does not create extra milestone events' do
          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.resource_milestone_events.count).to eq(old_issue.resource_milestone_events.count)
        end
      end

      context 'issue with due date' do
        let(:date) { Date.parse('2020-01-10') }

        let(:old_issue) do
          create(:issue, title: title, description: description, project: old_project, author: author, due_date: date)
        end

        before do
          SystemNoteService.change_due_date(old_issue, old_project, author, old_issue.due_date)
        end

        it 'keeps the same due date' do
          new_issue = clone_service.execute(old_issue, new_project)

          expect(new_issue.due_date).to eq(date)
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
