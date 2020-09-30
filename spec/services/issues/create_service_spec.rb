# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CreateService do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    let_it_be(:assignee) { create(:user) }
    let_it_be(:milestone) { create(:milestone, project: project) }
    let(:issue) { described_class.new(project, user, opts).execute }

    context 'when params are valid' do
      let_it_be(:labels) { create_pair(:label, project: project) }

      before_all do
        project.add_maintainer(user)
        project.add_maintainer(assignee)
      end

      let(:opts) do
        { title: 'Awesome issue',
          description: 'please fix',
          assignee_ids: [assignee.id],
          label_ids: labels.map(&:id),
          milestone_id: milestone.id,
          milestone: milestone,
          due_date: Date.tomorrow }
      end

      it 'creates the issue with the given params' do
        expect(Issuable::CommonSystemNotesService).to receive_message_chain(:new, :execute)

        expect(issue).to be_persisted
        expect(issue.title).to eq('Awesome issue')
        expect(issue.assignees).to eq [assignee]
        expect(issue.labels).to match_array labels
        expect(issue.milestone).to eq milestone
        expect(issue.due_date).to eq Date.tomorrow
      end

      context 'when skip_system_notes is true' do
        let(:issue) { described_class.new(project, user, opts).execute(skip_system_notes: true) }

        it 'does not call Issuable::CommonSystemNotesService' do
          expect(Issuable::CommonSystemNotesService).not_to receive(:new)

          issue
        end
      end

      it_behaves_like 'not an incident issue'

      context 'issue is incident type' do
        before do
          opts.merge!(issue_type: 'incident')
        end

        let(:current_user) { user }
        let(:incident_label_attributes) { attributes_for(:label, :incident) }

        subject { issue }

        it_behaves_like 'incident issue'
        it_behaves_like 'an incident management tracked event', :incident_management_incident_created

        it 'does create an incident label' do
          expect { subject }
            .to change { Label.where(incident_label_attributes).count }.by(1)
        end

        context 'when invalid' do
          before do
            opts.merge!(title: '')
          end

          it 'does not create an incident label prematurely' do
            expect { subject }.not_to change(Label, :count)
          end
        end
      end

      it 'refreshes the number of open issues', :use_clean_rails_memory_store_caching do
        expect { issue }.to change { project.open_issues_count }.from(0).to(1)
      end

      context 'when current user cannot admin issues in the project' do
        let_it_be(:guest) { create(:user) }

        before_all do
          project.add_guest(guest)
        end

        it 'filters out params that cannot be set without the :admin_issue permission' do
          issue = described_class.new(project, guest, opts).execute

          expect(issue).to be_persisted
          expect(issue.title).to eq('Awesome issue')
          expect(issue.description).to eq('please fix')
          expect(issue.assignees).to be_empty
          expect(issue.labels).to be_empty
          expect(issue.milestone).to be_nil
          expect(issue.due_date).to be_nil
        end

        it 'creates confidential issues' do
          issue = described_class.new(project, guest, confidential: true).execute

          expect(issue.confidential).to be_truthy
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

      it 'moves the issue to the end, in an asynchronous worker' do
        expect(IssuePlacementWorker).to receive(:perform_async).with(be_nil, Integer)

        described_class.new(project, user, opts).execute
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
          project.update!(group: group)
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

      context 'when labels is nil' do
        let(:opts) do
          { title: 'Title',
            description: 'Description',
            labels: nil }
        end

        it 'does not assign label' do
          expect(issue.labels).to be_empty
        end
      end

      context 'when labels is nil and label_ids is present' do
        let(:opts) do
          { title: 'Title',
            description: 'Description',
            labels: nil,
            label_ids: labels.map(&:id) }
        end

        it 'assigns group labels' do
          expect(issue.labels).to match_array labels
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

      context 'when assignee is set' do
        let(:opts) do
          { title: 'Title',
            description: 'Description',
            assignees: [assignee] }
        end

        it 'invalidates open issues counter for assignees when issue is assigned' do
          project.add_maintainer(assignee)

          described_class.new(project, user, opts).execute

          expect(assignee.assigned_open_issues_count).to eq 1
        end
      end

      context 'when duplicate label titles are given' do
        let(:label) { create(:label, project: project) }

        let(:opts) do
          { title: 'Title',
            description: 'Description',
            labels: [label.title, label.title] }
        end

        it 'assigns the label once' do
          expect(issue.labels).to contain_exactly(label)
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

      context 'after_save callback to store_mentions' do
        context 'when mentionable attributes change' do
          let(:opts) { { title: 'Title', description: "Description with #{user.to_reference}" } }

          it 'saves mentions' do
            expect_next_instance_of(Issue) do |instance|
              expect(instance).to receive(:store_mentions!).and_call_original
            end
            expect(issue.user_mentions.count).to eq 1
          end
        end

        context 'when save fails' do
          let(:opts) { { title: '', label_ids: labels.map(&:id), milestone_id: milestone.id } }

          it 'does not call store_mentions' do
            expect_next_instance_of(Issue) do |instance|
              expect(instance).not_to receive(:store_mentions!).and_call_original
            end
            expect(issue.valid?).to be false
            expect(issue.user_mentions.count).to eq 0
          end
        end
      end

      it 'deletes milestone issues count cache' do
        expect_next_instance_of(Milestones::IssuesCountService, milestone) do |service|
          expect(service).to receive(:delete_cache).and_call_original
        end

        issue
      end
    end

    context 'issue create service' do
      context 'assignees' do
        before_all do
          project.add_maintainer(user)
        end

        it 'removes assignee when user id is invalid' do
          opts = { title: 'Title', description: 'Description', assignee_ids: [-1] }

          issue = described_class.new(project, user, opts).execute

          expect(issue.assignees).to be_empty
        end

        it 'removes assignee when user id is 0' do
          opts = { title: 'Title', description: 'Description', assignee_ids: [0] }

          issue = described_class.new(project, user, opts).execute

          expect(issue.assignees).to be_empty
        end

        it 'saves assignee when user id is valid' do
          project.add_maintainer(assignee)
          opts = { title: 'Title', description: 'Description', assignee_ids: [assignee.id] }

          issue = described_class.new(project, user, opts).execute

          expect(issue.assignees).to eq([assignee])
        end

        context "when issuable feature is private" do
          before do
            project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE,
                                           merge_requests_access_level: ProjectFeature::PRIVATE)
          end

          levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

          levels.each do |level|
            it "removes not authorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
              project.update!(visibility_level: level)
              opts = { title: 'Title', description: 'Description', assignee_ids: [assignee.id] }

              issue = described_class.new(project, user, opts).execute

              expect(issue.assignees).to be_empty
            end
          end
        end
      end
    end

    it_behaves_like 'issuable record that supports quick actions' do
      let(:issuable) { described_class.new(project, user, params).execute }
    end

    context 'Quick actions' do
      context 'with assignee and milestone in params and command' do
        let(:opts) do
          {
            assignee_ids: [create(:user).id],
            milestone_id: 1,
            title: 'Title',
            description: %(/assign @#{assignee.username}\n/milestone %"#{milestone.name}")
          }
        end

        before_all do
          project.add_maintainer(user)
          project.add_maintainer(assignee)
        end

        it 'assigns and sets milestone to issuable from command' do
          expect(issue).to be_persisted
          expect(issue.assignees).to eq([assignee])
          expect(issue.milestone).to eq(milestone)
        end
      end
    end

    context 'resolving discussions' do
      let_it_be(:discussion) { create(:diff_note_on_merge_request).to_discussion }
      let_it_be(:merge_request) { discussion.noteable }
      let_it_be(:project) { merge_request.source_project }

      before_all do
        project.add_maintainer(user)
      end

      describe 'for a single discussion' do
        let(:opts) { { discussion_to_resolve: discussion.id, merge_request_to_resolve_discussions_of: merge_request.iid } }

        it 'resolves the discussion' do
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

        it 'can set nil explicitly to the title and description' do
          issue = described_class.new(project, user,
                                      merge_request_to_resolve_discussions_of: merge_request,
                                      description: nil,
                                      title: nil).execute

          expect(issue.description).to be_nil
          expect(issue.title).to be_nil
        end
      end

      describe 'for a merge request' do
        let(:opts) { { merge_request_to_resolve_discussions_of: merge_request.iid } }

        it 'resolves the discussion' do
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

        it 'can set nil explicitly to the title and description' do
          issue = described_class.new(project, user,
                                      merge_request_to_resolve_discussions_of: merge_request,
                                      description: nil,
                                      title: nil).execute

          expect(issue.description).to be_nil
          expect(issue.title).to be_nil
        end
      end
    end

    context 'checking spam' do
      include_context 'includes Spam constants'

      let(:title) { 'Legit issue' }
      let(:description) { 'please fix' }
      let(:opts) do
        {
          title: title,
          description: description,
          request: double(:request, env: {})
        }
      end

      subject { described_class.new(project, user, opts) }

      before do
        stub_feature_flags(allow_possible_spam: false)
      end

      context 'when reCAPTCHA was verified' do
        let(:log_user)  { user }
        let(:spam_logs) { create_list(:spam_log, 2, user: log_user, title: title) }
        let(:target_spam_log) { spam_logs.last }

        before do
          opts[:recaptcha_verified] = true
          opts[:spam_log_id] = target_spam_log.id

          expect(Spam::SpamVerdictService).not_to receive(:new)
        end

        it 'does not mark an issue as spam' do
          expect(issue).not_to be_spam
        end

        it 'creates a valid issue' do
          expect(issue).to be_valid
        end

        it 'does not assign a spam_log to the issue' do
          expect(issue.spam_log).to be_nil
        end

        it 'marks related spam_log as recaptcha_verified' do
          expect { issue }.to change { target_spam_log.reload.recaptcha_verified }.from(false).to(true)
        end

        context 'when spam log does not belong to a user' do
          let(:log_user) { create(:user) }

          it 'does not mark spam_log as recaptcha_verified' do
            expect { issue }.not_to change { target_spam_log.reload.recaptcha_verified }
          end
        end
      end

      context 'when reCAPTCHA was not verified' do
        before do
          expect_next_instance_of(Spam::SpamActionService) do |spam_service|
            expect(spam_service).to receive_messages(check_for_spam?: true)
          end
        end

        context 'when SpamVerdictService requires reCAPTCHA' do
          before do
            expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
              expect(verdict_service).to receive(:execute).and_return(CONDITIONAL_ALLOW)
            end
          end

          it 'does not mark the issue as spam' do
            expect(issue).not_to be_spam
          end

          it 'marks the issue as needing reCAPTCHA' do
            expect(issue.needs_recaptcha?).to be_truthy
          end

          it 'invalidates the issue' do
            expect(issue).to be_invalid
          end

          it 'creates a new spam_log' do
            expect { issue }
                .to have_spam_log(title: title, description: description, user_id: user.id, noteable_type: 'Issue')
          end
        end

        context 'when SpamVerdictService disallows creation' do
          before do
            expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
              expect(verdict_service).to receive(:execute).and_return(DISALLOW)
            end
          end

          context 'when allow_possible_spam feature flag is false' do
            it 'marks the issue as spam' do
              expect(issue).to be_spam
            end

            it 'does not mark the issue as needing reCAPTCHA' do
              expect(issue.needs_recaptcha?).to be_falsey
            end

            it 'invalidates the issue' do
              expect(issue).to be_invalid
            end

            it 'creates a new spam_log' do
              expect { issue }
                  .to have_spam_log(title: title, description: description, user_id: user.id, noteable_type: 'Issue')
            end
          end

          context 'when allow_possible_spam feature flag is true' do
            before do
              stub_feature_flags(allow_possible_spam: true)
            end

            it 'does not mark the issue as spam' do
              expect(issue).not_to be_spam
            end

            it 'does not mark the issue as needing reCAPTCHA' do
              expect(issue.needs_recaptcha?).to be_falsey
            end

            it 'creates a valid issue' do
              expect(issue).to be_valid
            end

            it 'creates a new spam_log' do
              expect { issue }
                  .to have_spam_log(title: title, description: description, user_id: user.id, noteable_type: 'Issue')
            end
          end
        end

        context 'when the SpamVerdictService allows creation' do
          before do
            expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
              expect(verdict_service).to receive(:execute).and_return(ALLOW)
            end
          end

          it 'does not mark an issue as spam' do
            expect(issue).not_to be_spam
          end

          it 'creates a valid issue' do
            expect(issue).to be_valid
          end

          it 'does not assign a spam_log to an issue' do
            expect(issue.spam_log).to be_nil
          end
        end
      end
    end
  end
end
