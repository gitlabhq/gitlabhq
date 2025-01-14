# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::MoveService, feature_category: :team_planning do
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

  let_it_be_with_reload(:old_issue) do
    create(
      :issue,
      title: title,
      description: description,
      project: old_project,
      author: author,
      imported_from: :gitlab_migration,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
  end

  subject(:move_service) do
    described_class.new(container: old_project, current_user: user)
  end

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  shared_context 'user can move issue' do
    before do
      old_project.add_reporter(user)
      new_project.add_reporter(user)
    end
  end

  describe '#execute' do
    shared_context 'issue move executed' do
      let!(:new_issue) { move_service.execute(old_issue, new_project) }
    end

    # We will use this service in order to move WorkItem to a new project. As WorkItem inherits from Issue, there
    # should not be any problem with passing a WorkItem instead of an Issue to this service.
    # Adding a small test case to cover this.
    context "when we pass a work_item" do
      include_context 'user can move issue'

      subject(:move) { move_service.execute(original_work_item, new_project) }

      context "work item is of issue type" do
        let_it_be_with_reload(:original_work_item) { create(:work_item, :issue, project: old_project, author: author) }

        it { expect { move }.to change { new_project.issues.count }.by(1) }
      end

      context "work item is of task type" do
        let_it_be_with_reload(:original_work_item) { create(:work_item, :task, project: old_project, author: author) }

        it { expect { move }.to raise_error(described_class::MoveError) }
      end
    end

    context 'when issue creation fails' do
      include_context 'user can move issue'

      before do
        allow_next_instance_of(Issues::CreateService) do |create_service|
          allow(create_service).to receive(:execute).and_return(ServiceResponse.error(message: 'some error'))
        end
      end

      it 'raises a move error' do
        expect { move_service.execute(old_issue, new_project) }.to raise_error(
          Issues::MoveService::MoveError,
          'some error'
        )
      end
    end

    context 'issue movable' do
      include_context 'user can move issue'

      it 'creates resource state event' do
        expect { move_service.execute(old_issue, new_project) }.to change(ResourceStateEvent.where(issue_id: old_issue), :count).by(1)
      end

      context 'generic issue' do
        include_context 'issue move executed'

        it 'creates a new issue in a new project' do
          expect(new_issue.project).to eq new_project
          expect(new_issue.namespace_id).to eq new_project.project_namespace_id
        end

        it 'copies issue title' do
          expect(new_issue.title).to eq title
        end

        it 'copies issue description' do
          expect(new_issue.description).to eq description
        end

        it 'restores imported_from to none' do
          expect(new_issue.imported_from).to eq 'none'
          expect(old_issue.reload.imported_from).to eq 'gitlab_migration'
        end

        it 'adds system note to old issue at the end' do
          expect(old_issue.notes.last.note).to start_with 'moved to'
        end

        it 'adds system note to new issue at the end', :freeze_time do
          system_note = new_issue.notes.last

          expect(system_note.note).to start_with 'moved from'
          expect(system_note.created_at).to be_like_time(Time.current)
        end

        it 'closes old issue' do
          expect(old_issue.closed?).to be true
        end

        it 'persists new issue' do
          expect(new_issue.persisted?).to be true
        end

        it 'persists all changes' do
          expect(old_issue.changed?).to be false
          expect(new_issue.changed?).to be false
        end

        it 'preserves author' do
          expect(new_issue.author).to eq author
        end

        it 'creates a new internal id for issue' do
          expect(new_issue.iid).to be 1
        end

        it 'marks issue as moved' do
          expect(old_issue.moved?).to eq true
          expect(old_issue.moved_to).to eq new_issue
        end

        it 'marks issue as closed' do
          expect(old_issue.closed?).to eq true
        end

        it 'preserves create time' do
          expect(old_issue.created_at).to eq new_issue.created_at
        end
      end

      context 'issue with children' do
        let_it_be(:task1) { create(:issue, :task, project: old_issue.project) }
        let_it_be(:task2) { create(:issue, :task, project: old_issue.project) }

        before_all do
          create(:parent_link, work_item_parent_id: old_issue.id, work_item_id: task1.id)
          create(:parent_link, work_item_parent_id: old_issue.id, work_item_id: task2.id)
        end

        it "moves the issue and each of it's children", :aggregate_failures do
          expect { move_service.execute(old_issue, new_project) }.to change { Issue.count }.by(3)
          expect(new_project.issues.count).to eq(3)
          expect(new_project.issues.pluck(:title)).to match_array(
            [old_issue, task1, task2].map(&:title)
          )
        end
      end

      context 'issue with award emoji' do
        let!(:award_emoji) { create(:award_emoji, awardable: old_issue) }

        it 'copies the award emoji' do
          old_issue.reload
          new_issue = move_service.execute(old_issue, new_project)

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
          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.resource_milestone_events.count).to eq(old_issue.resource_milestone_events.count)
        end
      end

      context 'issue with due date' do
        let(:old_issue) do
          create(:issue, title: title, description: description, project: old_project, author: author, due_date: '2020-01-10')
        end

        before do
          old_issue.update!(due_date: Date.today)
          SystemNoteService.change_start_date_or_due_date(old_issue, old_project, author, old_issue.previous_changes.slice('due_date'))
        end

        it 'does not create extra system notes' do
          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.notes.count).to eq(old_issue.notes.count)
        end
      end

      context 'issue with assignee' do
        let_it_be(:assignee) { create(:user) }

        before do
          old_issue.assignees = [assignee]
        end

        it 'preserves assignee with access to the new issue' do
          new_project.add_reporter(assignee)

          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.assignees).to eq([assignee])
        end

        it 'ignores assignee without access to the new issue' do
          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.assignees).to be_empty
        end
      end

      context 'issue with contacts' do
        let_it_be(:contacts) { create_list(:contact, 2, group: group) }

        before do
          old_issue.customer_relations_contacts = contacts
        end

        it 'preserves contacts' do
          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.customer_relations_contacts).to eq(contacts)
        end

        context 'when moving to another root group' do
          let(:another_project) { create(:project, namespace: create(:group)) }

          before do
            another_project.add_reporter(user)
          end

          it 'does not preserve contacts' do
            new_issue = move_service.execute(old_issue, another_project)

            expect(new_issue.customer_relations_contacts).to be_empty
          end
        end
      end

      context 'moving to same project' do
        let(:new_project) { old_project }

        it 'raises error' do
          expect { move_service.execute(old_issue, new_project) }
            .to raise_error(StandardError, /Cannot move issue/)
        end
      end

      context 'project issue hooks' do
        let_it_be(:old_project_hook) { create(:project_hook, project: old_project, issues_events: true) }
        let_it_be(:new_project_hook) { create(:project_hook, project: new_project, issues_events: true) }

        let(:expected_new_project_hook_payload) do
          hash_including(
            event_type: 'issue',
            object_kind: 'issue',
            object_attributes: include(
              project_id: new_project.id,
              state: 'opened',
              action: 'open'
            )
          )
        end

        let(:expected_old_project_hook_payload) do
          hash_including(
            event_type: 'issue',
            object_kind: 'issue',
            changes: {
              state_id: { current: 2, previous: 1 },
              closed_at: { current: kind_of(Time), previous: nil },
              updated_at: { current: kind_of(Time), previous: kind_of(Time) }
            },
            object_attributes: include(
              id: old_issue.id,
              closed_at: kind_of(Time),
              state: 'closed',
              action: 'close'
            )
          )
        end

        it 'executes project issue hooks for both projects' do
          expect_next_instance_of(
            WebHookService,
            new_project_hook,
            expected_new_project_hook_payload,
            'issue_hooks',
            idempotency_key: anything
          ) do |service|
            expect(service).to receive(:async_execute).once
          end

          expect_next_instance_of(
            WebHookService,
            old_project_hook,
            expected_old_project_hook_payload,
            'issue_hooks',
            idempotency_key: anything
          ) do |service|
            expect(service).to receive(:async_execute).once
          end

          move_service.execute(old_issue, new_project)
        end
      end

      # These tests verify that notes are copied. More thorough tests are in
      # the unit test for Notes::CopyService.
      context 'issue with notes' do
        let!(:notes) do
          [
            create(:note, noteable: old_issue, project: old_project, created_at: 2.weeks.ago, updated_at: 1.week.ago, imported_from: :gitlab_migration),
            create(:note, noteable: old_issue, project: old_project, imported_from: :gitlab_migration)
          ]
        end

        let(:copied_notes) { new_issue.notes.limit(notes.size) } # Remove the system note added by the copy itself

        include_context 'issue move executed'

        it 'copies existing notes in order' do
          expect(copied_notes.order('id ASC').pluck(:note)).to eq(notes.map(&:note))
        end

        it 'resets the imported_from value to none' do
          expect(notes.map(&:reload)).to all(have_attributes(imported_from: 'gitlab_migration'))

          expect(copied_notes.pluck(:imported_from)).to all(eq('none'))
        end
      end

      context 'issue with a design', :clean_gitlab_redis_shared_state do
        let_it_be(:new_project) { create(:project) }

        let!(:design) { create(:design, :with_lfs_file, issue: old_issue) }
        let!(:note) { create(:diff_note_on_design, noteable: design, issue: old_issue, project: old_issue.project) }
        let(:subject) { move_service.execute(old_issue, new_project) }

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

      context 'issue with timelogs' do
        before do
          create(:timelog, issue: old_issue)
        end

        it 'calls CopyTimelogsWorker' do
          expect(WorkItems::CopyTimelogsWorker).to receive(:perform_async).with(old_issue.id, kind_of(Integer))

          move_service.execute(old_issue, new_project)
        end
      end

      context 'issue relative position' do
        let(:subject) { move_service.execute(old_issue, new_project) }

        it_behaves_like 'copy or reset relative position'
      end

      context 'issue with escalation status' do
        it 'keeps the escalation status' do
          escalation_status = create(:incident_management_issuable_escalation_status, issue: old_issue)

          move_service.execute(old_issue, new_project)

          expect(escalation_status.reload.issue).to eq(old_issue)
        end
      end
    end

    describe 'move permissions' do
      let(:move) { move_service.execute(old_issue, new_project) }

      context 'user is reporter in both projects' do
        include_context 'user can move issue'
        it { expect { move }.not_to raise_error }
      end

      context 'user is reporter only in new project' do
        before do
          new_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter only in old project' do
        before do
          old_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter in one project and guest in another' do
        before do
          new_project.add_guest(user)
          old_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue has already been moved' do
        include_context 'user can move issue'

        let(:moved_to_issue) { create(:issue) }

        let(:old_issue) do
          create(:issue, project: old_project, author: author, moved_to: moved_to_issue)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue is not persisted' do
        include_context 'user can move issue'
        let(:old_issue) { build(:issue, project: old_project, author: author) }

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end
    end
  end

  describe '#recreate_related_issues' do
    include_context 'user can move issue'

    let(:admin) { create(:admin) }
    let(:authorized_project) { create(:project) }
    let(:authorized_project2) { create(:project) }
    let(:unauthorized_project) { create(:project) }

    let(:authorized_issue_b) { create(:issue, project: authorized_project) }
    let(:authorized_issue_c) { create(:issue, project: authorized_project2) }
    let(:authorized_issue_d) { create(:issue, project: authorized_project2) }
    let(:unauthorized_issue) { create(:issue, project: unauthorized_project) }

    let!(:issue_link_a) { create(:issue_link, source: old_issue, target: authorized_issue_b) }
    let!(:issue_link_b) { create(:issue_link, source: old_issue, target: unauthorized_issue) }
    let!(:issue_link_c) { create(:issue_link, source: old_issue, target: authorized_issue_c) }
    let!(:issue_link_d) { create(:issue_link, source: authorized_issue_d, target: old_issue) }

    before do
      authorized_project.add_developer(user)
      authorized_project.add_developer(admin)
      authorized_project2.add_developer(user)
      authorized_project2.add_developer(admin)
    end

    context 'multiple related issues' do
      context 'when admin mode is enabled', :enable_admin_mode do
        it 'recreates all related issues and retains permissions' do
          new_issue = move_service.execute(old_issue, new_project)

          recreated_links = IssueLink.where(source: new_issue).or(IssueLink.where(target: new_issue))
          old_links_count = IssueLink.where(source: old_issue).or(IssueLink.where(target: old_issue)).count

          expect(recreated_links.count).to eq(4)
          expect(old_links_count).to eq(0)

          recreated_links.each do |link|
            expect(link.namespace_id).to eq(link.source.namespace_id)
          end

          expect(new_issue.related_issues(admin))
            .to match_array([authorized_issue_b, authorized_issue_c, authorized_issue_d, unauthorized_issue])

          expect(new_issue.related_issues(user))
            .to match_array([authorized_issue_b, authorized_issue_c, authorized_issue_d])

          expect(authorized_issue_d.related_issues(user))
            .to match_array([new_issue])
        end

        it 'does not recreate related issues when there are no related links' do
          IssueLink.where(source: old_issue).or(IssueLink.where(target: old_issue)).delete_all

          new_issue = move_service.execute(old_issue, new_project)
          recreated_links = IssueLink.where(source: new_issue).or(IssueLink.where(target: new_issue))

          expect(recreated_links.count).to eq(0)
        end
      end

      context 'when admin mode is disabled' do
        it 'recreates authorized related issues only and retains permissions' do
          new_issue = move_service.execute(old_issue, new_project)

          recreated_links = IssueLink.where(source: new_issue).or(IssueLink.where(target: new_issue))
          old_links_count = IssueLink.where(source: old_issue).or(IssueLink.where(target: old_issue)).count

          expect(recreated_links.count).to eq(4)
          expect(old_links_count).to eq(0)

          recreated_links.each do |link|
            expect(link.namespace_id).to eq(link.source.namespace_id)
          end

          expect(new_issue.related_issues(admin))
            .to match_array([authorized_issue_b, authorized_issue_c, authorized_issue_d])

          expect(new_issue.related_issues(user))
            .to match_array([authorized_issue_b, authorized_issue_c, authorized_issue_d])

          expect(authorized_issue_d.related_issues(user))
            .to match_array([new_issue])
        end
      end
    end
  end

  context 'updating sent notifications' do
    let!(:old_issue_notification_1) { create(:sent_notification, project: old_issue.project, noteable: old_issue) }
    let!(:old_issue_notification_2) { create(:sent_notification, project: old_issue.project, noteable: old_issue) }
    let!(:other_issue_notification) { create(:sent_notification, project: old_issue.project) }

    include_context 'user can move issue'

    context 'when issue is from service desk', :aggregate_failures do
      before do
        allow(old_issue).to receive(:from_service_desk?).and_return(true)
      end

      it 'updates moved issue sent notifications' do
        new_issue = move_service.execute(old_issue, new_project)

        old_issue_notification_1.reload
        old_issue_notification_2.reload
        expect(old_issue_notification_1.project_id).to eq(new_issue.project_id)
        expect(old_issue_notification_1.noteable_id).to eq(new_issue.id)
        expect(old_issue_notification_2.project_id).to eq(new_issue.project_id)
        expect(old_issue_notification_2.noteable_id).to eq(new_issue.id)
      end

      it 'does not update other issues sent notifications' do
        expect do
          move_service.execute(old_issue, new_project)
          other_issue_notification.reload
        end.not_to change { other_issue_notification.noteable_id }
      end

      context 'when the issue has children' do
        let(:task) { create(:issue, :task, project: old_issue.project, author: Users::Internal.support_bot) }
        let!(:task_notification) { create(:sent_notification, project: old_issue.project, noteable: task) }

        before do
          create(:parent_link, work_item_parent_id: old_issue.id, work_item_id: task.id)
        end

        it 'updates moved issue sent notifications' do
          new_issue = move_service.execute(old_issue, new_project)
          new_task = Issue.where(work_item_type: WorkItems::Type.default_by_type(:task)).last

          old_issue_notification_1.reload
          old_issue_notification_2.reload
          task_notification.reload
          expect(old_issue_notification_1.project_id).to eq(new_issue.project_id)
          expect(old_issue_notification_1.noteable_id).to eq(new_issue.id)
          expect(old_issue_notification_2.project_id).to eq(new_issue.project_id)
          expect(old_issue_notification_2.noteable_id).to eq(new_issue.id)
          expect(task_notification.project_id).to eq(new_issue.project_id)
          expect(task_notification.noteable_id).to eq(new_task.id)
        end
      end
    end

    context 'when issue is not from service desk' do
      it 'does not update sent notifications' do
        move_service.execute(old_issue, new_project)

        old_issue_notification_1.reload
        old_issue_notification_2.reload
        expect(old_issue_notification_1.project_id).to eq(old_issue.project_id)
        expect(old_issue_notification_1.noteable_id).to eq(old_issue.id)
        expect(old_issue_notification_2.project_id).to eq(old_issue.project_id)
        expect(old_issue_notification_2.noteable_id).to eq(old_issue.id)
      end
    end
  end

  context 'copying email participants' do
    let!(:participant1) { create(:issue_email_participant, email: 'user1@example.com', issue: old_issue) }
    let!(:participant2) { create(:issue_email_participant, email: 'user2@example.com', issue: old_issue) }
    let!(:participant3) { create(:issue_email_participant, email: 'other_project_customer@example.com') }

    include_context 'user can move issue'

    subject(:new_issue) do
      move_service.execute(old_issue, new_project)
    end

    it 'copies moved issue email participants' do
      new_issue

      expect(participant1.reload.issue).to eq(old_issue)
      expect(participant2.reload.issue).to eq(old_issue)
      expect(new_issue.issue_email_participants.pluck(:email))
       .to match_array([participant1.email, participant2.email])
    end
  end
end
