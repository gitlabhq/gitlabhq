# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Notify, feature_category: :code_review_workflow do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include EmailHelpers
  include EmailsHelper
  include RepoHelpers
  include MembersHelper

  include_context 'gitlab email notification'

  let(:current_user_sanitized) { 'www_example_com' }

  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:current_user, reload: true) { create(:user, email: "current@email.com", name: 'www.example.com') }
  let_it_be(:assignee, reload: true) { create(:user, email: 'assignee@example.com', name: 'John Doe') }
  let_it_be(:reviewer, reload: true) { create(:user, email: 'reviewer@example.com', name: 'Jane Doe') }

  let(:previous_assignee1) { create(:user, name: 'Previous Assignee 1') }
  let(:previous_assignee_ids) { [previous_assignee1.id] }

  let_it_be(:merge_request, reload: true) do
    create(
      :merge_request,
      source_project: project,
      target_project: project,
      author: current_user,
      assignees: [assignee],
      reviewers: [reviewer],
      description: 'Awesome description'
    )
  end

  let_it_be(:issue, reload: true) do
    create(
      :issue,
      author: current_user,
      assignees: [assignee],
      project: project,
      description: 'My awesome description!'
    )
  end

  shared_examples 'an assignee email' do
    let(:recipient) { assignee }

    it_behaves_like 'an email sent to a user'

    it 'is sent to the assignee as the author' do
      aggregate_failures do
        expect_sender(current_user)
        expect(subject).to deliver_to(recipient.notification_email_or_default)
      end
    end
  end

  shared_examples 'an assignee email with previous assignees' do
    context 'when all assignees are removed' do
      before do
        resource.update!(assignees: [])
      end

      it_behaves_like 'email with default notification reason'

      it 'uses fixed copy "All assignees were removed"' do
        is_expected.to have_body_text("<p> All assignees were removed. </p>")
        is_expected.to have_plain_text_content("All assignees were removed.")
      end
    end

    context 'with multiple previous assignees' do
      let(:previous_assignee2) { create(:user, name: 'Previous Assignee 2') }
      let(:previous_assignee_ids) { [previous_assignee1.id, previous_assignee2.id] }

      it_behaves_like 'email with default notification reason'

      it 'has the correct subject and body' do
        aggregate_failures do
          is_expected.to have_referable_subject(resource, reply: true)
          is_expected.to have_body_text("<p> <strong>#{assignee.name}</strong> was added as an assignee. </p> <p> <strong>#{previous_assignee1.name} and #{previous_assignee2.name}</strong> were removed as assignees. </p>")
          is_expected.to have_plain_text_content("#{assignee.name} was added as an assignee.")
          is_expected.to have_plain_text_content("#{previous_assignee1.name} and #{previous_assignee2.name} were removed as assignees.")
        end
      end
    end
  end

  describe 'with non-ASCII characters' do
    before do
      described_class.test_email('test@test.com', 'Subject', 'Some body with 中文 &mdash;').deliver
    end

    subject { ActionMailer::Base.deliveries.last }

    it 'removes HTML encoding and uses UTF-8 charset' do
      expect(subject.charset).to eq('UTF-8')
      expect(subject.body).to include('中文 —')
    end
  end

  context 'for a project' do
    context 'for merge requests' do
      let(:push_user) { create(:user) }
      let(:commit_limit) { NotificationService::NEW_COMMIT_EMAIL_DISPLAY_LIMIT }

      describe 'that are new' do
        subject { described_class.new_merge_request_email(merge_request.assignee_ids.first, merge_request.id) }

        it_behaves_like 'an assignee email'

        it_behaves_like 'an email starting a new thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request)
            is_expected.to have_body_text(project_merge_request_path(project, merge_request))
            is_expected.to have_body_text(merge_request.source_branch)
            is_expected.to have_body_text(merge_request.target_branch)
            is_expected.to have_body_text(reviewer.name)
          end
        end

        it 'contains the description' do
          is_expected.to have_body_text merge_request.description
        end

        context 'when sent with a reason' do
          subject { described_class.new_merge_request_email(merge_request.assignee_ids.first, merge_request.id, NotificationReason::ASSIGNED) }

          it_behaves_like 'appearance header and footer enabled'
          it_behaves_like 'appearance header and footer not enabled'

          it 'includes the reason in a header' do
            is_expected.to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
          end
        end

        it 'contains a link to merge request author' do
          is_expected.to have_body_text merge_request.author_name
          is_expected.to have_body_text 'created a merge request:'
        end

        it 'contains a link to the merge request url' do
          is_expected.to have_link(merge_request.to_reference, href: project_merge_request_url(merge_request.target_project, merge_request))
        end
      end

      describe 'that are reassigned' do
        subject { described_class.reassigned_merge_request_email(recipient.id, merge_request.id, previous_assignee_ids, current_user.id) }

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like "an unsubscribeable thread"
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it_behaves_like 'an assignee email with previous assignees' do
          let(:resource) { merge_request }
        end

        it 'is sent as the author' do
          expect_sender(current_user)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text(previous_assignee1.name)
            is_expected.to have_body_text(project_merge_request_path(project, merge_request))
            is_expected.to have_body_text(assignee.name)
          end
        end

        context 'when sent with a reason', type: :helper do
          subject { described_class.reassigned_merge_request_email(recipient.id, merge_request.id, [previous_assignee1.id], current_user.id, NotificationReason::ASSIGNED) }

          it_behaves_like 'appearance header and footer enabled'
          it_behaves_like 'appearance header and footer not enabled'

          it 'includes the reason in a header' do
            is_expected.to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
          end

          it 'includes the reason in the footer' do
            text = EmailsHelper.instance_method(:notification_reason_text).bind_call(self, reason: NotificationReason::ASSIGNED, format: :html)
            is_expected.to have_body_text(text)

            new_subject = described_class.reassigned_merge_request_email(recipient.id, merge_request.id, [previous_assignee1.id], current_user.id, NotificationReason::MENTIONED)
            text = EmailsHelper.instance_method(:notification_reason_text).bind_call(self, reason: NotificationReason::MENTIONED, format: :html)
            expect(new_subject).to have_body_text(text)

            new_subject = described_class.reassigned_merge_request_email(recipient.id, merge_request.id, [previous_assignee1.id], current_user.id, nil)
            text = EmailsHelper.instance_method(:notification_reason_text).bind_call(self, format: :html)
            expect(new_subject).to have_body_text(text)
          end
        end
      end

      describe 'that are new with a description' do
        subject { described_class.new_merge_request_email(merge_request.assignee_ids.first, merge_request.id) }

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like "an unsubscribeable thread"
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'contains the description' do
          is_expected.to have_body_text(merge_request.description)
        end
      end

      describe 'that have been relabeled' do
        subject { described_class.relabeled_merge_request_email(recipient.id, merge_request.id, %w[foo bar baz], current_user.id) }

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'an email with a labels subscriptions link in its footer'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'is sent as the author' do
          expect_sender(current_user)
        end

        it 'has the correct subject and body' do
          is_expected.to have_referable_subject(merge_request, reply: true)
          is_expected.to have_body_text('foo, bar, and baz')
          is_expected.to have_body_text(project_merge_request_path(project, merge_request))
        end
      end

      shared_examples 'a push to an existing merge request' do
        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'is sent as the push user' do
          expect_sender(push_user)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text("#{push_user.name} pushed new commits")
            is_expected.to have_body_text(project_merge_request_path(project, merge_request))
            is_expected.to have_link(merge_request.to_reference, href: project_merge_request_url(merge_request.target_project, merge_request))
          end
        end
      end

      shared_examples 'shows the compare url between first and last commits' do |count|
        it 'shows the compare url between first and last commits' do
          commit_id_1 = existing_commits.first[:short_id]
          commit_id_2 = existing_commits.last[:short_id]

          is_expected.to have_link("#{commit_id_1}...#{commit_id_2}", href: project_compare_url(project, from: commit_id_1, to: commit_id_2))
          is_expected.to have_body_text("#{count} commits from branch `#{merge_request.target_branch}`")
        end
      end

      shared_examples 'shows new commit urls' do |count|
        it 'shows new commit urls' do
          displayed_new_commits.each do |commit|
            is_expected.to have_link(commit[:short_id], href: project_commit_url(project, commit[:short_id]))
            is_expected.to have_body_text(commit[:title])
          end
        end

        it 'does not show hidden new commit urls' do
          hidden_new_commits.each do |commit|
            is_expected.not_to have_link(commit[:short_id], href: project_commit_url(project, commit[:short_id]))
            is_expected.not_to have_body_text(commit[:title])
          end
        end
      end

      describe 'that have no new commits' do
        subject do
          described_class.push_to_merge_request_email(recipient.id, merge_request.id, push_user.id, new_commits: [], total_new_commits_count: 0, existing_commits: [], total_existing_commits_count: 0)
        end

        it_behaves_like 'a push to an existing merge request'
      end

      describe 'that have fewer than the commit truncation limit' do
        let(:new_commits) { merge_request.commits }
        let(:displayed_new_commits) { new_commits }
        let(:hidden_new_commits) { [] }

        subject do
          described_class.push_to_merge_request_email(
            recipient.id, merge_request.id, push_user.id,
            new_commits: new_commits, total_new_commits_count: new_commits.length,
            existing_commits: [], total_existing_commits_count: 0
          )
        end

        it_behaves_like 'a push to an existing merge request'
        it_behaves_like 'shows new commit urls'
      end

      describe 'that have more than the commit truncation limit' do
        let(:new_commits) do
          Array.new(commit_limit + 10) do |i|
            {
              short_id: SecureRandom.hex(4),
              title: "This is commit #{i}"
            }
          end
        end

        let(:displayed_new_commits) { new_commits.first(commit_limit) }
        let(:hidden_new_commits) { new_commits.last(10) }

        subject do
          described_class.push_to_merge_request_email(
            recipient.id, merge_request.id, push_user.id,
            new_commits: displayed_new_commits, total_new_commits_count: commit_limit + 10,
            existing_commits: [], total_existing_commits_count: 0
          )
        end

        it_behaves_like 'a push to an existing merge request'
        it_behaves_like 'shows new commit urls'

        it 'shows "and more" message' do
          is_expected.to have_body_text("And 10 more")
        end
      end

      describe 'that have new commits on top of an existing one' do
        let(:existing_commits) { [merge_request.commits.first] }

        subject do
          described_class.push_to_merge_request_email(
            recipient.id, merge_request.id, push_user.id,
            new_commits: merge_request.commits, total_new_commits_count: merge_request.commits.length,
            existing_commits: existing_commits, total_existing_commits_count: existing_commits.length
          )
        end

        it_behaves_like 'a push to an existing merge request'

        it 'shows the existing commit' do
          commit_id = existing_commits.first.short_id
          is_expected.to have_link(commit_id, href: project_commit_url(project, commit_id))
          is_expected.to have_body_text("1 commit from branch `#{merge_request.target_branch}`")
        end
      end

      describe 'that have new commits on top of two existing ones' do
        let(:existing_commits) { [merge_request.commits.first, merge_request.commits.second] }

        subject do
          described_class.push_to_merge_request_email(
            recipient.id, merge_request.id, push_user.id,
            new_commits: merge_request.commits, total_new_commits_count: merge_request.commits.length,
            existing_commits: existing_commits, total_existing_commits_count: existing_commits.length
          )
        end

        it_behaves_like 'a push to an existing merge request'
        it_behaves_like 'shows the compare url between first and last commits', 2
      end

      describe 'that have new commits on top of more than two existing ones' do
        let(:existing_commits) do
          [merge_request.commits.first] + ([double(:commit)] * 3) + [merge_request.commits.second]
        end

        subject do
          described_class.push_to_merge_request_email(
            recipient.id, merge_request.id, push_user.id,
            new_commits: merge_request.commits, total_new_commits_count: merge_request.commits.length,
            existing_commits: existing_commits, total_existing_commits_count: existing_commits.length
          )
        end

        it_behaves_like 'a push to an existing merge request'
        it_behaves_like 'shows the compare url between first and last commits', 5
      end
    end

    describe '#mail_thread' do
      let_it_be(:mail_thread_note) { create(:note) }

      let(:headers) do
        {
          from: 'someone@test.com',
          to: 'someone-else@test.com',
          subject: 'something',
          template_name: '_note_email' # re-use this for testing
        }
      end

      let(:mailer) do
        mailer = described_class.new
        mailer.instance_variable_set(:@note, mail_thread_note)
        mailer.instance_variable_set(:@target_url, "https://some.link")
        mailer
      end

      context 'the model has no namespace' do
        before do
          stub_const('TopLevelThing', Class.new)

          TopLevelThing.class_eval do
            include Referable
            include Noteable

            def to_reference(*_args)
              'tlt-ref'
            end

            def id
              'tlt-id'
            end
          end
        end

        subject do
          mailer.send(:mail_thread, TopLevelThing.new, headers)
        end

        it 'has X-GitLab-Namespaced-Thing-ID header' do
          expect(subject.header['X-GitLab-TopLevelThing-ID'].value).to eq('tlt-id')
        end
      end

      context 'the model has a namespace' do
        before do
          stub_const('Namespaced::Thing', Class.new)

          Namespaced::Thing.class_eval do
            include Referable
            include Noteable

            def to_reference(*_args)
              'some-reference'
            end

            def id
              'some-id'
            end
          end
        end

        subject do
          mailer.send(:mail_thread, Namespaced::Thing.new, headers)
        end

        it 'has X-GitLab-Namespaced-Thing-ID header' do
          expect(subject.header['X-GitLab-Namespaced-Thing-ID'].value).to eq('some-id')
        end
      end
    end

    context 'for snippet notes' do
      let(:project_snippet) { create(:project_snippet, project: project) }
      let(:project_snippet_note) { create(:note_on_project_snippet, project: project, noteable: project_snippet) }

      subject { described_class.note_snippet_email(project_snippet_note.author_id, project_snippet_note.id) }

      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
        let(:model) { project_snippet }
      end

      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has the correct subject' do
        is_expected.to have_referable_subject(project_snippet, reply: true)
      end

      it 'has the correct body' do
        is_expected.to have_body_text project_snippet_note.note
      end

      it 'links to the project snippet' do
        target_url = project_snippet_url(
          project,
          project_snippet_note.noteable,
          { anchor: "note_#{project_snippet_note.id}" }
        )
        is_expected.to have_body_text target_url
      end
    end

    describe 'for design notes' do
      let_it_be(:design) { create(:design, :with_file) }
      let_it_be(:recipient) { create(:user) }
      let_it_be(:note) do
        create(:diff_note_on_design, noteable: design, note: "Hello #{recipient.to_reference}")
      end

      let(:header_name) { 'X-Gitlab-DesignManagement-Design-ID' }
      let(:refer_to_design) do
        have_attributes(subject: a_string_including(design.filename))
      end

      subject { described_class.note_design_email(recipient.id, note.id) }

      it { is_expected.to have_header(header_name, design.id.to_s) }

      it { is_expected.to have_body_text(design.filename) }

      it { is_expected.to refer_to_design }
    end

    describe 'project was moved' do
      let(:recipient) { user }

      subject { described_class.project_was_moved_email(project.id, user.id, "gitlab/gitlab") }

      it_behaves_like 'an email sent to a user'
      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'has the correct subject and body' do
        is_expected.to have_subject("#{project.name} | Project was moved")
        is_expected.to have_body_text project.full_name
        is_expected.to have_body_text(project.ssh_url_to_repo)
      end
    end

    describe 'project access requested' do
      let(:project) do
        create(:project, :public) do |project|
          project.add_maintainer(project.first_owner)
        end
      end

      let(:project_member) do
        project.request_access(user)
        project.requesters.find_by(user_id: user.id)
      end

      subject { described_class.member_access_requested_email('project', project_member.id, recipient.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'contains all the useful information' do
        to_emails = subject.header[:to].addrs.map(&:address)
        expect(to_emails).to eq([recipient.notification_email_or_default])

        is_expected.to have_subject "Request to join the #{project.full_name} project"
        is_expected.to have_body_text project.full_name
        is_expected.to have_body_text project_project_members_url(project)
        is_expected.to have_body_text project_member.human_access
      end
    end

    describe 'project access changed' do
      let(:owner) { create(:user, name: "Chang O'Keefe") }
      let(:project) { create(:project, :public, namespace: owner.namespace) }
      let(:project_member) { create(:project_member, project: project, user: user) }
      let(:organization) { project.organization }

      subject { described_class.member_access_granted_email('project', project_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'contains all the useful information', :aggregate_failures do
        is_expected.to have_subject "Access to the #{project.full_name} project was granted"
        is_expected.to have_body_text project.full_name
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text organization.name
        is_expected.to have_body_text organization.web_url
        is_expected.to have_body_text project_member.human_access
        is_expected.to have_body_text 'leave the project'
        is_expected.to have_body_text project_url(project, leave: 1)
      end

      context 'when ui_for_organizations feature is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it 'contains all the useful information', :aggregate_failures do
          is_expected.to have_subject "Access to the #{project.full_name} project was granted"
          is_expected.to have_body_text project.full_name
          is_expected.to have_body_text project.web_url
          is_expected.to have_body_text project_member.human_access
          is_expected.to have_body_text 'default role'
          is_expected.to have_body_text 'leave the project'
          is_expected.to have_body_text project_url(project, leave: 1)
        end
      end
    end

    def invite_to_project(project, inviter:, user: nil)
      create(
        :project_member,
        :developer,
        project: project,
        invite_token: '1234',
        invite_email: 'toto@example.com',
        user: user,
        created_by: inviter
      )
    end

    describe 'project invitation accepted' do
      let(:invited_user) { create(:user, name: 'invited user') }
      let(:recipient) { create(:user, maintainer_of: project) }
      let(:project_member) do
        invitee = invite_to_project(project, inviter: recipient)
        invitee.accept_invite!(invited_user)
        invitee
      end

      subject { described_class.member_invite_accepted_email('project', project_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'an email sent to a user'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation accepted'
        is_expected.to have_body_text project.full_name
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.invite_email
        is_expected.to have_body_text invited_user.name
      end
    end

    context 'items that are noteable, the email for a note' do
      let(:note_author) { create(:user, name: 'author_name') }
      let(:note) { create(:note, project: project, author: note_author) }

      before do
        allow(Note).to receive(:find).with(note.id).and_return(note)
      end

      describe 'on a commit' do
        let(:commit) { project.commit }

        before do
          allow(note).to receive(:noteable).and_return(commit)
        end

        subject { described_class.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { commit }
        end

        it_behaves_like 'it should show Gmail Actions View Commit link'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_subject("Re: #{project.name} | #{commit.title} (#{commit.short_id})")
            is_expected.to have_body_text(commit.short_id)
          end
        end
      end

      describe 'on a merge request' do
        let(:note_on_merge_request_path) { project_merge_request_path(project, merge_request, anchor: "note_#{note.id}") }

        before do
          allow(note).to receive(:noteable).and_return(merge_request)
        end

        subject { described_class.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text note_on_merge_request_path
          end
        end
      end
    end

    context 'items that are noteable, the email for a discussion note' do
      let(:note_author) { create(:user, name: 'author_name') }

      before do
        allow(Note).to receive(:find).with(note.id).and_return(note)
      end

      shared_examples 'a discussion note email' do |model|
        it_behaves_like 'it should have Gmail Actions links'

        # Two tests with flakiness:1 are coming from this test:
        #
        # 1. https://gitlab.com/gitlab-org/gitlab/-/issues/464578
        # 2. https://gitlab.com/gitlab-org/gitlab/-/issues/464577
        it 'is sent to the given recipient as the author',
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/464578' do
          aggregate_failures do
            expect_sender(note_author)
            expect(subject).to deliver_to(recipient.notification_email_or_default)
          end
        end

        it 'contains the message from the note' do
          is_expected.to have_body_text note.note
        end

        it 'contains an introduction' do
          issuable_url = "project_#{note.noteable_type.underscore}_url"
          anchor = "note_#{note.id}"

          is_expected.to have_body_text "started a new <a href=\"#{public_send(issuable_url, project, note.noteable, anchor: anchor)}\">discussion</a>"
        end

        context 'when a comment on an existing discussion' do
          let(:first_note) { create_note }
          let(:note) { create(model, author: note_author, noteable: nil, in_reply_to: first_note) }

          it 'contains an introduction' do
            is_expected.to have_body_text 'commented on a'
          end
        end
      end

      describe 'on a commit' do
        let(:commit) { project.commit }
        let(:note) { create_note }

        def create_note
          create(:discussion_note_on_commit, commit_id: commit.id, project: project, author: note_author)
        end

        before do
          allow(note).to receive(:noteable).and_return(commit)
        end

        subject { described_class.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'a discussion note email', :discussion_note_on_commit
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { commit }
        end

        it_behaves_like 'it should show Gmail Actions View Commit link'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'has the correct subject' do
          is_expected.to have_subject "Re: #{project.name} | #{commit.title} (#{commit.short_id})"
        end

        it 'contains a link to the commit' do
          is_expected.to have_body_text commit.short_id
        end
      end

      describe 'on a merge request' do
        let(:note) { create_note }
        let(:note_on_merge_request_path) { project_merge_request_path(project, merge_request, anchor: "note_#{note.id}") }

        def create_note
          create(:discussion_note_on_merge_request, noteable: merge_request, project: project, author: note_author)
        end

        before do
          allow(note).to receive(:noteable).and_return(merge_request)
        end

        subject { described_class.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'a discussion note email', :discussion_note_on_merge_request
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'has the correct subject' do
          is_expected.to have_referable_subject(merge_request, reply: true)
        end

        it 'contains a link to the merge request note' do
          is_expected.to have_body_text note_on_merge_request_path
        end
      end

      describe 'on an issue' do
        let(:note) { create_note }
        let(:note_on_issue_path) { project_issue_path(project, issue, anchor: "note_#{note.id}") }

        def create_note
          create(:discussion_note_on_issue, noteable: issue, project: project, author: note_author)
        end

        before do
          allow(note).to receive(:noteable).and_return(issue)
        end

        subject { described_class.note_issue_email(recipient.id, note.id) }

        it_behaves_like 'a discussion note email', :discussion_note_on_issue
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { issue }
        end

        it_behaves_like 'it should show Gmail Actions View Issue link'
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'has the correct subject' do
          is_expected.to have_referable_subject(issue, reply: true)
        end

        it 'contains a link to the issue note' do
          is_expected.to have_body_text note_on_issue_path
        end
      end
    end

    context 'items that are noteable, the email for a diff discussion note' do
      let(:note_author) { create(:user, name: 'author_name') }

      before do
        allow(Note).to receive(:find).with(note.id).and_return(note)
      end

      shared_examples 'an email for a note on a diff discussion' do |model|
        context 'when note is not on text' do
          before do
            allow(note.discussion).to receive(:on_text?).and_return(false)
          end

          it 'does not include diffs with character-level highlighting' do
            is_expected.not_to have_body_text '<span class="n">path</span>'
          end
        end

        context 'when the project does not show diffs in emails' do
          before do
            allow(project).to receive(:show_diff_preview_in_email?).and_return(false)
          end

          it "does not show diff and displays a separate message" do
            is_expected.to have_body_text 'This project does not include diff previews in email notifications'
            is_expected.not_to have_body_text '<span class="n">path</span>'
          end
        end

        it 'includes diffs with character-level highlighting' do
          is_expected.to have_body_text '<span class="n">path</span>'
        end

        it 'contains a link to the diff file' do
          is_expected.to have_body_text note.diff_file.file_path
        end

        it_behaves_like 'it should have Gmail Actions links'

        # Two tests with flakiness:1 are coming from this test:
        #
        # 1. https://gitlab.com/gitlab-org/gitlab/-/issues/464579
        # 2. https://gitlab.com/gitlab-org/gitlab/-/issues/464580
        it 'is sent to the given recipient as the author',
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/464579' do
          aggregate_failures do
            expect_sender(note_author)
            expect(subject).to deliver_to(recipient.notification_email_or_default)
          end
        end

        it 'contains the message from the note' do
          is_expected.to have_body_text note.note
        end

        it 'contains an introduction' do
          is_expected.to have_body_text 'started a new discussion on'
        end

        context 'when a comment on an existing discussion' do
          let(:first_note) { create(model) } # rubocop:disable Rails/SaveBang
          let(:note) { create(model, author: note_author, noteable: nil, in_reply_to: first_note) }

          it 'contains an introduction' do
            is_expected.to have_body_text 'commented on a discussion on'
          end
        end
      end

      describe 'on a commit' do
        let(:commit) { project.commit }
        let(:note) { create(:diff_note_on_commit, author: note_author, project: project) }

        subject { described_class.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'an email for a note on a diff discussion', :diff_note_on_commit
        it_behaves_like 'it should show Gmail Actions View Commit link'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'
      end

      describe 'on a merge request' do
        let(:note) { create(:diff_note_on_merge_request, author: note_author, noteable: merge_request, project: project) }

        subject { described_class.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'an email for a note on a diff discussion', :diff_note_on_merge_request
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'
      end
    end

    context 'for service desk issues' do
      let_it_be(:issue_email_participant) do
        create(:issue_email_participant, issue: issue, email: 'service.desk@example.com')
      end

      before do
        issue.update!(external_author: 'service.desk@example.com')
      end

      describe 'thank you email', feature_category: :service_desk do
        subject { described_class.service_desk_thank_you_email(issue.id) }

        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'
        it_behaves_like 'a mail with default delivery method'

        it 'has the correct recipient' do
          is_expected.to deliver_to('service.desk@example.com')
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, include_project: false, reply: true)
            is_expected.to have_body_text("Thank you for your support request! We are tracking your request as ticket #{issue.to_reference}, and will respond as soon as we can.")
          end
        end

        it 'uses service bot name by default' do
          expect_sender(Users::Internal.support_bot)
        end

        context 'when custom outgoing name is set' do
          let_it_be(:settings) { create(:service_desk_setting, project: project, outgoing_name: 'some custom name') }

          it 'uses custom name in "from" header' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq('some custom name')
            expect(sender.address).to eq(gitlab_sender)
          end
        end

        context 'when custom outgoing name is empty' do
          let_it_be(:settings) { create(:service_desk_setting, project: project, outgoing_name: '') }

          it 'uses service bot name' do
            expect_sender(Users::Internal.support_bot)
          end
        end

        context 'when custom email is enabled' do
          let_it_be(:credentials) { build(:service_desk_custom_email_credential, project: project).save!(validate: false) }
          let_it_be(:verification) { create(:service_desk_custom_email_verification, project: project) }

          let_it_be(:settings) do
            create(
              :service_desk_setting,
              project: project,
              custom_email: 'supersupport@example.com'
            )
          end

          before_all do
            verification.mark_as_finished!
            project.reset
            settings.update!(custom_email_enabled: true)
          end

          it 'uses custom email and service bot name in "from" header' do
            expect_sender(Users::Internal.support_bot, sender_email: 'supersupport@example.com')
          end

          it 'uses SMTP delivery method and has correct settings' do
            expect_service_desk_custom_email_delivery_options(settings)
          end
        end
      end

      describe 'new note email', feature_category: :service_desk do
        let_it_be(:first_note) { create(:discussion_note_on_issue, note: 'Hello world') }

        subject { described_class.service_desk_new_note_email(issue.id, first_note.id, issue_email_participant) }

        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'
        it_behaves_like 'a mail with default delivery method'

        it 'has the correct recipient' do
          is_expected.to deliver_to('service.desk@example.com')
        end

        it 'uses author\'s name in "from" header' do
          expect_sender(first_note.author)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, include_project: false, reply: true)
            is_expected.to have_body_text(first_note.note)
          end
        end

        context 'when custom email is enabled' do
          let_it_be(:credentials) { build(:service_desk_custom_email_credential, project: project).save!(validate: false) }
          let_it_be(:verification) { create(:service_desk_custom_email_verification, project: project) }

          let_it_be(:settings) do
            create(
              :service_desk_setting,
              project: project,
              custom_email: 'supersupport@example.com'
            )
          end

          before_all do
            verification.mark_as_finished!
            project.reset
            settings.update!(custom_email_enabled: true)
          end

          it 'uses custom email and author\'s name in "from" header' do
            expect_sender(first_note.author, sender_email: project.service_desk_setting.custom_email)
          end

          it 'uses SMTP delivery method and has correct settings' do
            expect_service_desk_custom_email_delivery_options(settings)
          end
        end
      end
    end
  end

  context 'for issues', feature_category: :team_planning do
    shared_examples 'mailer for an issue' do |group_level = false|
      describe 'that are new' do
        subject { described_class.new_issue_email(issue.assignees.first.id, issue.id) }

        it_behaves_like 'an assignee email'

        it_behaves_like 'an email starting a new thread with reply-by-email enabled', group_level do
          let(:model) { issue }
        end

        it_behaves_like 'it should show Gmail Actions View Issue link', group_level
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue)
            is_expected.to have_body_text(Gitlab::UrlBuilder.build(issue))
            is_expected.not_to have_body_text 'This project does not include diff previews in email notifications'
          end
        end

        it 'contains the description' do
          is_expected.to have_body_text issue.description
        end

        context 'when issue is confidential' do
          before do
            issue.update_attribute(:confidential, true)
          end

          it 'has a confidential header set to true' do
            is_expected.to have_header('X-GitLab-ConfidentialIssue', 'true')
          end
        end

        context 'when sent with a reason' do
          subject { described_class.new_issue_email(issue.assignees.first.id, issue.id, NotificationReason::ASSIGNED) }

          it_behaves_like 'appearance header and footer enabled'
          it_behaves_like 'appearance header and footer not enabled'

          it 'includes the reason in a header' do
            is_expected.to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
          end
        end

        it 'contains a link to issue author' do
          is_expected.to have_body_text(issue.author_name)
          is_expected.to have_body_text 'created an issue:'
          is_expected.to have_link(issue.to_reference, href: Gitlab::UrlBuilder.build(issue))
        end

        it 'contains a link to the issue' do
          is_expected.to have_body_text(issue.to_reference(full: false))
        end
      end

      describe 'that are reassigned' do
        subject { described_class.reassigned_issue_email(recipient.id, issue.id, previous_assignee_ids, current_user.id) }

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled', group_level do
          let(:model) { issue }
        end

        it_behaves_like 'it should show Gmail Actions View Issue link', group_level
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'
        it_behaves_like 'email with default notification reason'
        it_behaves_like 'email with link to issue'

        it 'is sent as the author' do
          expect_sender(current_user)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text("<p> <strong>#{assignee.name}</strong> was added as an assignee. </p> <p> <strong>#{previous_assignee1.name}</strong> was removed as an assignee. </p>")
            is_expected.to have_plain_text_content("#{assignee.name} was added as an assignee.")
            is_expected.to have_plain_text_content("#{previous_assignee1.name} was removed as an assignee.")
          end
        end

        it_behaves_like 'an assignee email with previous assignees' do
          let(:resource) { issue }
        end

        context 'without previous assignees' do
          subject { described_class.reassigned_issue_email(recipient.id, issue.id, [], current_user.id) }

          it_behaves_like 'email with default notification reason'
          it_behaves_like 'email with link to issue'

          it 'does not mention any previous assignees' do
            is_expected.to have_body_text("<p> <strong>#{assignee.name}</strong> was added as an assignee. </p>")
            is_expected.to have_plain_text_content("#{assignee.name} was added as an assignee.")
          end
        end

        context 'when sent with a reason' do
          subject { described_class.reassigned_issue_email(recipient.id, issue.id, [previous_assignee1.id], current_user.id, NotificationReason::ASSIGNED) }

          it_behaves_like 'appearance header and footer enabled'
          it_behaves_like 'appearance header and footer not enabled'

          it 'includes the reason in a header' do
            is_expected.to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
          end
        end

        context 'when sent with a non default locale' do
          let(:email_obj) { create(:email, :confirmed, user_id: recipient.id, email: '123@abc') }
          let(:recipient) { create(:user, preferred_language: :zh_CN) }

          it 'is sent with html lang attribute set to the user\'s preferred language' do
            recipient.notification_email = email_obj.email
            recipient.save!
            is_expected.to have_body_text '<html lang="zh-CN">'
          end
        end
      end

      describe 'that have been relabeled' do
        subject { described_class.relabeled_issue_email(recipient.id, issue.id, %w[foo bar baz], current_user.id) }

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled', group_level do
          let(:model) { issue }
        end

        it_behaves_like 'it should show Gmail Actions View Issue link', group_level
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'an email with a labels subscriptions link in its footer', group_level
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'is sent as the author' do
          expect_sender(current_user)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text('foo, bar, and baz')
            is_expected.to have_body_text(Gitlab::UrlBuilder.build(issue))
          end
        end

        context 'with a preferred language' do
          before do
            Gitlab::I18n.locale = :es
          end

          after do
            Gitlab::I18n.use_default_locale
          end

          it 'always generates the email using the default language' do
            is_expected.to have_body_text('foo, bar, and baz')
          end
        end
      end

      describe 'that are due soon' do
        subject { described_class.issue_due_email(recipient.id, issue.id) }

        before do
          issue.update!(due_date: Date.tomorrow)
        end

        it_behaves_like 'an answer to an existing thread with reply-by-email enabled', group_level do
          let(:model) { issue }
        end

        it 'contains a link to the issue' do
          is_expected.to have_body_text(issue.to_reference(full: false))
        end

        it_behaves_like 'it should show Gmail Actions View Issue link', group_level
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'
      end

      describe 'status changed' do
        let(:status) { 'closed' }

        subject { described_class.issue_status_changed_email(recipient.id, issue.id, status, current_user.id) }

        it_behaves_like 'an answer to an existing thread with reply-by-email enabled', group_level do
          let(:model) { issue }
        end

        it_behaves_like 'it should show Gmail Actions View Issue link', group_level
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'is sent as the author' do
          expect_sender(current_user)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text(status)
            is_expected.to have_body_text(current_user_sanitized)
            is_expected.to have_body_text(Gitlab::UrlBuilder.build(issue))
          end
        end
      end

      describe 'closed' do
        subject { described_class.closed_issue_email(recipient.id, issue.id, current_user.id) }

        it_behaves_like 'an answer to an existing thread with reply-by-email enabled', group_level do
          let(:model) { issue }
        end

        it_behaves_like 'it should show Gmail Actions View Issue link', group_level
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'
        it_behaves_like 'email with default notification reason'
        it_behaves_like 'email with link to issue'

        it 'is sent as the author' do
          expect_sender(current_user)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text("Issue was closed by #{current_user_sanitized}")
            is_expected.to have_plain_text_content("Issue was closed by #{current_user_sanitized}")
          end
        end

        context 'via commit' do
          let(:closing_commit) { project.commit }

          subject { described_class.closed_issue_email(recipient.id, issue.id, current_user.id, closed_via: closing_commit.id) }

          before do
            allow(Ability).to receive(:allowed?).with(recipient, :mark_note_as_internal, anything).and_return(true)
            allow(Ability).to receive(:allowed?).with(recipient, :download_code, anything).and_return(true)
          end

          it_behaves_like 'email with default notification reason'
          it_behaves_like 'email with link to issue'

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.to have_body_text("Issue was closed by #{current_user_sanitized} with #{closing_commit.id}")
              is_expected.to have_plain_text_content("Issue was closed by #{current_user_sanitized} with #{closing_commit.id}")
            end
          end
        end

        context 'via merge request' do
          let(:closing_merge_request) { merge_request }

          subject { described_class.closed_issue_email(recipient.id, issue.id, current_user.id, closed_via: closing_merge_request) }

          before do
            allow(Ability).to receive(:allowed?).with(recipient, :read_cross_project, :global).and_return(true)
            allow(Ability).to receive(:allowed?).with(recipient, :mark_note_as_internal, anything).and_return(true)
            allow(Ability).to receive(:allowed?).with(recipient, :read_merge_request, anything).and_return(true)
          end

          it_behaves_like 'email with default notification reason'
          it_behaves_like 'email with link to issue'

          it 'has the correct subject and body' do
            aggregate_failures do
              url = project_merge_request_url(project, closing_merge_request)
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.to have_body_text("Issue was closed by #{current_user_sanitized} with merge request " +
                                            %(<a href="#{url}">#{closing_merge_request.to_reference}</a>))
              is_expected.to have_plain_text_content("Issue was closed by #{current_user_sanitized} with merge request " \
                                                    "#{closing_merge_request.to_reference} (#{url})")
            end
          end
        end
      end

      describe 'moved to another project' do
        let(:new_issue) { create(:issue) }

        subject { described_class.issue_moved_email(recipient, issue, new_issue, current_user) }

        context 'when a user has permissions to access the new issue' do
          before do
            new_issue.project.add_developer(recipient)
          end

          it_behaves_like 'an answer to an existing thread with reply-by-email enabled', group_level do
            let(:model) { issue }
          end

          it_behaves_like 'it should show Gmail Actions View Issue link', group_level
          it_behaves_like 'an unsubscribeable thread'

          it 'contains description about action taken' do
            is_expected.to have_body_text 'Issue was moved to another project'
          end

          it 'has the correct subject and body' do
            new_issue_url = Gitlab::UrlBuilder.build(new_issue)

            aggregate_failures do
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.to have_body_text(new_issue_url)
              is_expected.to have_body_text(Gitlab::UrlBuilder.build(issue))
            end
          end

          it 'contains the issue title' do
            is_expected.to have_body_text new_issue.title
          end
        end

        context 'when a user does not permissions to access the new issue' do
          it 'has the correct subject and body' do
            new_issue_url = Gitlab::UrlBuilder.build(new_issue)

            aggregate_failures do
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.not_to have_body_text(new_issue_url)
              is_expected.to have_body_text(Gitlab::UrlBuilder.build(issue))
            end
          end

          it 'does not contain the issue title' do
            is_expected.not_to have_body_text new_issue.title
          end

          it 'contains information about missing permissions' do
            is_expected.to have_body_text "You don't have access to the project."
          end
        end
      end

      describe 'for issue notes' do
        let(:host) { Gitlab.config.gitlab.host }

        subject { described_class.note_issue_email(recipient.id, note_subject.id) }

        context 'in discussion' do
          let_it_be(:first_note) { create(:discussion_note, noteable: issue, project: issue.project) }
          let_it_be(:second_note) { create(:discussion_note, noteable: issue, project: issue.project, in_reply_to: first_note) }
          let_it_be(:third_note) { create(:discussion_note, noteable: issue, project: issue.project, in_reply_to: second_note) }

          before_all do
            first_note.noteable.reload.update_attribute(:confidential, "true")
          end

          let(:note_subject) { third_note }

          it_behaves_like 'an email sent to a user'
          it_behaves_like 'appearance header and footer enabled'
          it_behaves_like 'appearance header and footer not enabled'

          it 'has In-Reply-To header pointing to previous note in discussion' do
            expect(subject.header['In-Reply-To'].message_ids).to eq(["note_#{second_note.id}@#{host}"])
          end

          it 'has References header including the notes and issue of the discussion' do
            expect(subject.header['References'].message_ids).to include(
              "issue_#{first_note.noteable.id}@#{host}",
              "note_#{first_note.id}@#{host}",
              "note_#{second_note.id}@#{host}"
            )
          end

          it 'has X-GitLab-Discussion-ID header' do
            expect(subject.header['X-GitLab-Discussion-ID'].value).to eq(third_note.discussion.id)
          end

          it 'has a confidential header set to true' do
            is_expected.to have_header('X-GitLab-ConfidentialIssue', 'true')
          end
        end

        context 'individual issue comments' do
          let_it_be(:note_author) { create(:user, name: 'author_name') }
          let_it_be_with_refind(:note) { create(:note, noteable: issue, project: issue.project, author: note_author) }

          let(:note_subject) { note }

          it_behaves_like 'a note email'
          it_behaves_like 'an answer to an existing thread with reply-by-email enabled', group_level do
            let(:model) { issue }
          end

          it_behaves_like 'it should show Gmail Actions View Issue link', group_level
          it_behaves_like 'an unsubscribeable thread'
          it_behaves_like 'appearance header and footer enabled'
          it_behaves_like 'appearance header and footer not enabled'

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.to have_body_text(Gitlab::UrlBuilder.build(issue, anchor: "note_#{note.id}"))
            end
          end

          context 'when noteable is confidential' do
            before_all do
              note.noteable.update_attribute(:confidential, "true")
            end

            it_behaves_like 'an email sent to a user'
            it_behaves_like 'appearance header and footer enabled'
            it_behaves_like 'appearance header and footer not enabled'

            it 'has a confidential header set to true' do
              expect(subject.header['X-GitLab-ConfidentialIssue'].value).to eq('true')
            end

            it 'has In-Reply-To header pointing to the issue' do
              expect(subject.header['In-Reply-To'].message_ids).to eq(["issue_#{note.noteable.id}@#{host}"])
            end

            it 'has References header including the notes and issue of the discussion' do
              expect(subject.header['References'].message_ids).to include("issue_#{note.noteable.id}@#{host}")
            end

            context 'with private references accessible to the recipient' do
              let_it_be(:private_project) { create(:project, :private) }
              let_it_be(:private_issue) { create(:issue, :closed, project: private_project) }

              before_all do
                private_project.add_guest(recipient)

                note.update!(note: private_issue.to_reference(full: true).to_s)
              end

              let(:html_part) { subject.body.parts.last.to_s }

              it 'does not redact the reference' do
                expect(html_part).to include("data-reference-type=\"issue\"")
                expect(html_part).to include("title=\"#{private_issue.title}\"")
              end

              it 'renders expanded issue references' do
                expect(html_part).to include("#{private_issue.to_reference(full: true)} (closed)")
              end
            end
          end
        end
      end
    end

    context 'when issue belongs to a project' do
      it_behaves_like 'mailer for an issue'
    end

    context 'when issue belongs to a group' do
      let_it_be_with_reload(:issue) do
        create(
          :issue,
          :group_level,
          author: current_user,
          assignees: [assignee],
          namespace: group,
          description: 'My awesome description!'
        )
      end

      it_behaves_like 'mailer for an issue', true
    end
  end

  context 'for a group' do
    describe 'group access requested' do
      let(:group) { create(:group, :public) }
      let(:organization) { group.organization }
      let(:group_member) do
        group.request_access(user)
        group.requesters.find_by(user_id: user.id)
      end

      subject { described_class.member_access_requested_email('group', group_member.id, recipient.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'an email sent to a user'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'contains all the useful information' do
        to_emails = subject.header[:to].addrs.map(&:address)
        expect(to_emails).to eq([recipient.notification_email_or_default])

        is_expected.to have_subject "Request to join the #{group.name} group"
        is_expected.to have_body_text group.name
        is_expected.to have_body_text group_group_members_url(group)
        is_expected.to have_body_text group_member.human_access
      end
    end

    describe 'group access changed' do
      let(:organization) { group.organization }
      let(:group_member) { create(:group_member, group: group, user: user) }
      let(:recipient) { user }

      subject { described_class.member_access_granted_email('group', group_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'an email sent to a user'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'contains all the useful information', :aggregate_failures do
        is_expected.to have_subject "Access to the #{group.name} group was granted"
        is_expected.to have_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text organization.name
        is_expected.to have_body_text organization.web_url
        is_expected.to have_body_text group_member.human_access
        is_expected.to have_body_text 'leave the group'
        is_expected.to have_body_text group_url(group, leave: 1)
      end

      context 'when ui_for_organizations feature is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it 'contains all the useful information', :aggregate_failures do
          is_expected.to have_subject "Access to the #{group.name} group was granted"
          is_expected.to have_body_text group.name
          is_expected.to have_body_text group.web_url
          is_expected.to have_body_text group_member.human_access
          is_expected.to have_body_text 'leave the group'
          is_expected.to have_body_text group_url(group, leave: 1)
        end
      end
    end

    def invite_to_group(group, inviter:, user: nil)
      create(
        :group_member,
        :developer,
        group: group,
        invite_token: '1234',
        invite_email: 'toto@example.com',
        user: user,
        created_by: inviter
      )
    end

    describe 'group invitation accepted' do
      let(:invited_user) { create(:user, name: 'invited user') }
      let(:owner) { create(:user, owner_of: group) }
      let(:group_member) do
        invitee = invite_to_group(group, inviter: owner)
        invitee.accept_invite!(invited_user)
        invitee
      end

      subject { described_class.member_invite_accepted_email('group', group_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation accepted'
        is_expected.to have_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.invite_email
        is_expected.to have_body_text invited_user.name
      end
    end

    describe 'group expiration date updated' do
      let_it_be(:group_member) { create(:group_member, group: group, expires_at: 1.day.from_now) }

      context 'when expiration date is changed' do
        subject { described_class.member_expiration_date_updated_email('group', group_member.id) }

        it_behaves_like 'an email sent from GitLab'
        it_behaves_like 'it should not have Gmail Actions links'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        context 'when expiration date is one day away' do
          it 'contains all the useful information' do
            is_expected.to have_subject 'Group membership expiration date changed'
            is_expected.to have_body_text group_member.user.name
            is_expected.to have_body_text group.name
            is_expected.to have_body_text group.web_url
            is_expected.to have_body_text group_group_members_url(group, search: group_member.user.username)
            is_expected.to have_body_text 'day.'
            is_expected.not_to have_body_text 'days.'
          end
        end

        context 'when expiration date is more than one day away' do
          before do
            group_member.update!(expires_at: 20.days.from_now)
          end

          it 'contains all the useful information' do
            is_expected.to have_subject 'Group membership expiration date changed'
            is_expected.to have_body_text group_member.user.name
            is_expected.to have_body_text group.name
            is_expected.to have_body_text group.web_url
            is_expected.to have_body_text group_group_members_url(group, search: group_member.user.username)
            is_expected.to have_body_text 'days.'
            is_expected.not_to have_body_text 'day.'
          end
        end

        context 'when a group member is newly given an expiration date' do
          let_it_be(:group_member) { create(:group_member, group: group) }

          before do
            group_member.update!(expires_at: 5.days.from_now)
          end

          subject { described_class.member_expiration_date_updated_email('group', group_member.id) }

          it 'contains all the useful information' do
            is_expected.to have_subject 'Group membership expiration date changed'
            is_expected.to have_body_text group_member.user.name
            is_expected.to have_body_text group.name
            is_expected.to have_body_text group.web_url
            is_expected.to have_body_text group_group_members_url(group, search: group_member.user.username)
            is_expected.to have_body_text 'days.'
            is_expected.not_to have_body_text 'day.'
          end
        end
      end

      context 'when expiration date is removed' do
        before do
          group_member.update!(expires_at: nil)
        end

        subject { described_class.member_expiration_date_updated_email('group', group_member.id) }

        it_behaves_like 'an email sent from GitLab'
        it_behaves_like 'it should not have Gmail Actions links'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'contains all the useful information' do
          is_expected.to have_subject 'Group membership expiration date removed'
          is_expected.to have_body_text group_member.user.name
          is_expected.to have_body_text group.name
        end
      end
    end

    describe 'membership about to expire' do
      context "with group membership" do
        let_it_be(:group_member) { create(:group_member, source: group, expires_at: 7.days.from_now) }

        subject { described_class.member_about_to_expire_email("Namespace", group_member.id) }

        it_behaves_like 'an email sent from GitLab'
        it_behaves_like 'it should not have Gmail Actions links'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'contains all the useful information' do
          is_expected.to deliver_to group_member.user.email
          is_expected.to have_subject "Your membership will expire in 7 days"
          is_expected.to have_body_text "group will expire in 7 days."
          is_expected.to have_body_text group_url(group)
          is_expected.to have_body_text group_group_members_url(group)
        end
      end

      context "with project membership" do
        let_it_be(:project_member) { create(:project_member, source: project, expires_at: 7.days.from_now) }

        subject { described_class.member_about_to_expire_email('Project', project_member.id) }

        it_behaves_like 'an email sent from GitLab'
        it_behaves_like 'it should not have Gmail Actions links'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'appearance header and footer enabled'
        it_behaves_like 'appearance header and footer not enabled'

        it 'contains all the useful information' do
          is_expected.to deliver_to project_member.user.email
          is_expected.to have_subject "Your membership will expire in 7 days"
          is_expected.to have_body_text "project will expire in 7 days."
          is_expected.to have_body_text project_url(project)
          is_expected.to have_body_text project_project_members_url(project)
        end
      end

      context "with expired membership" do
        let_it_be(:project_member) { create(:project_member, source: project, expires_at: Date.today) }

        subject { described_class.member_about_to_expire_email('Project', project_member.id) }

        it 'not deliver expiry email' do
          should_not_email_anyone
        end
      end

      context "with expiry notified membership" do
        let_it_be(:project_member) { create(:project_member, source: project, expires_at: 7.days.from_now, expiry_notified_at: Date.today) }

        subject { described_class.member_about_to_expire_email('Project', project_member.id) }

        it 'not deliver expiry email' do
          should_not_email_anyone
        end
      end
    end

    describe 'admin notification' do
      let(:example_site_path) { root_path }
      let(:user) { create(:user) }

      subject { @email = described_class.send_admin_notification(user.id, 'Admin announcement', 'Text') }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'

      it 'is sent to recipient' do
        is_expected.to deliver_to user.email
      end

      it 'has the correct subject' do
        is_expected.to have_subject 'Admin announcement'
      end

      it 'includes unsubscribe link' do
        unsubscribe_link = "http://localhost/unsubscribes/#{Base64.urlsafe_encode64(user.email)}"
        is_expected.to have_body_text(unsubscribe_link)
      end
    end
  end

  describe 'admin unsubscribe notification' do
    let(:user) { create(:user) }

    subject { @email = described_class.send_unsubscribed_notification(user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent to recipient' do
      is_expected.to deliver_to user.email
    end
  end

  describe 'confirmation if email changed' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user, email: 'old-email@mail.com') }

    before do
      stub_config_setting(email_subject_suffix: 'A Nice Suffix')
      perform_enqueued_jobs do
        user.email = "new-email@mail.com"
        user.save!
      end
    end

    subject { ActionMailer::Base.deliveries.first }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'is sent to the new user' do
      is_expected.to deliver_to 'new-email@mail.com'
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject('Confirmation instructions | A Nice Suffix')
        is_expected.to have_body_text(example_site_path)
      end
    end
  end

  describe 'email on push for a created branch' do
    let(:example_site_path) { root_path }
    let(:tree_path) { project_tree_path(project, "empty-branch") }

    subject { described_class.repository_push_email(project.id, author_id: user.id, ref: 'refs/heads/empty-branch', action: :create) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent as the author' do
      expect_sender(user)
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject("[Git][#{project.full_path}] Pushed new branch empty-branch")
        is_expected.to have_body_text(tree_path)
      end
    end
  end

  describe 'email on push for a created tag' do
    let(:example_site_path) { root_path }
    let(:tree_path) { project_tree_path(project, "v1.0") }

    subject { described_class.repository_push_email(project.id, author_id: user.id, ref: 'refs/tags/v1.0', action: :create) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent as the author' do
      expect_sender(user)
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject("[Git][#{project.full_path}] Pushed new tag v1.0")
        is_expected.to have_body_text(tree_path)
      end
    end
  end

  describe 'email on push for a deleted branch' do
    let(:example_site_path) { root_path }

    subject { described_class.repository_push_email(project.id, author_id: user.id, ref: 'refs/heads/master', action: :delete) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent as the author' do
      expect_sender(user)
    end

    it 'has the correct subject' do
      is_expected.to have_subject "[Git][#{project.full_path}] Deleted branch master"
    end
  end

  describe 'email on push for a deleted tag' do
    let(:example_site_path) { root_path }

    subject { described_class.repository_push_email(project.id, author_id: user.id, ref: 'refs/tags/v1.0', action: :delete) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent as the author' do
      expect_sender(user)
    end

    it 'has the correct subject' do
      is_expected.to have_subject "[Git][#{project.full_path}] Deleted tag v1.0"
    end
  end

  describe 'email on push with multiple commits' do
    let(:example_site_path) { root_path }
    let(:raw_compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, sample_image_commit.id, sample_commit.id) }
    let(:compare) { Compare.decorate(raw_compare, project) }
    let(:commits) { compare.commits }
    let(:diff_path) { project_compare_path(project, from: Commit.new(compare.base, project), to: Commit.new(compare.head, project)) }
    let(:send_from_committer_email) { false }
    let(:diff_refs) { Gitlab::Diff::DiffRefs.new(base_sha: project.merge_base_commit(sample_image_commit.id, sample_commit.id).id, head_sha: sample_commit.id) }

    subject { described_class.repository_push_email(project.id, author_id: user.id, ref: 'refs/heads/master', action: :push, compare: compare, reverse_compare: false, diff_refs: diff_refs, send_from_committer_email: send_from_committer_email) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent as the author' do
      expect_sender(user)
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject("[Git][#{project.full_path}][master] #{commits.length} commits: Ruby files modified")
        is_expected.to have_body_text('Change some files')
        is_expected.to have_body_text('def</span> <span class="nf">archive_formats_regex')
        is_expected.to have_body_text(diff_path)
        is_expected.not_to have_body_text('you are a member of')
      end
    end

    context "when set to send from committer email if domain matches" do
      let(:send_from_committer_email) { true }

      before do
        allow(Gitlab.config.gitlab).to receive(:host).and_return("gitlab.corp.company.com")
      end

      context "when the committer email domain is within the GitLab domain" do
        before do
          user.update_attribute(:email, "user@company.com")
          user.confirm
        end

        it "is sent from the committer email" do
          from  = subject.header[:from].addrs.first
          reply = subject.header[:reply_to].addrs.first

          aggregate_failures do
            expect(from.address).to eq(user.email)
            expect(reply.address).to eq(user.email)
          end
        end
      end

      context "when the committer email domain is not completely within the GitLab domain" do
        before do
          user.update_attribute(:email, "user@something.company.com")
          user.confirm
        end

        it "is sent from the default email" do
          from  = subject.header[:from].addrs.first
          reply = subject.header[:reply_to].addrs.first

          aggregate_failures do
            expect(from.address).to eq(gitlab_sender)
            expect(reply.address).to eq(gitlab_sender_reply_to)
          end
        end
      end

      context "when the committer email domain is outside the GitLab domain" do
        before do
          user.update_attribute(:email, "user@mpany.com")
          user.confirm
        end

        it "is sent from the default email" do
          from = subject.header[:from].addrs.first
          reply = subject.header[:reply_to].addrs.first

          aggregate_failures do
            expect(from.address).to eq(gitlab_sender)
            expect(reply.address).to eq(gitlab_sender_reply_to)
          end
        end
      end
    end
  end

  describe 'email on push with a single commit' do
    let(:example_site_path) { root_path }
    let(:raw_compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, sample_commit.parent_id, sample_commit.id) }
    let(:compare) { Compare.decorate(raw_compare, project) }
    let(:commits) { compare.commits }
    let(:diff_path) { project_commit_path(project, commits.first) }
    let(:diff_refs) { Gitlab::Diff::DiffRefs.new(base_sha: project.merge_base_commit(sample_image_commit.id, sample_commit.id).id, head_sha: sample_commit.id) }

    subject { described_class.repository_push_email(project.id, author_id: user.id, ref: 'refs/heads/master', action: :push, compare: compare, diff_refs: diff_refs) }

    it_behaves_like 'it should show Gmail Actions View Commit link'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent as the author' do
      expect_sender(user)
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject("[Git][#{project.full_path}][master] #{commits.first.title}")
        is_expected.to have_body_text('Change some files')
        is_expected.to have_body_text('def</span> <span class="nf">archive_formats_regex')
        is_expected.to have_body_text(diff_path)
      end
    end
  end

  describe 'HTML emails setting' do
    let(:multipart_mail) { described_class.project_was_moved_email(project.id, user.id, "gitlab/gitlab") }

    subject { multipart_mail }

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    context 'when disabled' do
      it 'only sends the text template' do
        stub_application_setting(html_emails_enabled: false)

        Gitlab::Email::Hook::EmailTemplateInterceptor
          .delivering_email(multipart_mail)

        expect(multipart_mail).to have_part_with('text/plain')
        expect(multipart_mail).not_to have_part_with('text/html')
      end
    end

    context 'when enabled' do
      it 'sends a multipart message' do
        stub_application_setting(html_emails_enabled: true)

        Gitlab::Email::Hook::EmailTemplateInterceptor
          .delivering_email(multipart_mail)

        expect(multipart_mail).to have_part_with('text/plain')
        expect(multipart_mail).to have_part_with('text/html')
      end
    end

    matcher :have_part_with do |expected|
      match do |actual|
        actual.body.parts.any? { |part| part.content_type.try(:match, /#{expected}/) }
      end
    end
  end

  context 'for personal snippet notes' do
    let(:personal_snippet) { create(:personal_snippet) }
    let(:personal_snippet_note) { create(:note_on_personal_snippet, noteable: personal_snippet) }

    subject { described_class.note_snippet_email(personal_snippet_note.author_id, personal_snippet_note.id) }

    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'has the correct subject' do
      is_expected.to have_referable_subject(personal_snippet, reply: true)
    end

    it 'has the correct body' do
      is_expected.to have_body_text personal_snippet_note.note
    end

    it 'links to the personal snippet' do
      target_url = gitlab_snippet_url(personal_snippet_note.noteable)
      is_expected.to have_body_text target_url
    end
  end

  describe 'merge request reviews' do
    let!(:review) { create(:review, project: project, merge_request: merge_request) }
    let!(:notes) { create_list(:note, 3, review: review, project: project, author: review.author, noteable: merge_request) }

    subject { described_class.new_review_email(recipient.id, review.id) }

    it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
      let(:model) { review.merge_request }
    end

    it_behaves_like 'it should show Gmail Actions View Merge request link'
    it_behaves_like 'an unsubscribeable thread'

    it 'is sent to the given recipient as the author' do
      aggregate_failures do
        expect_sender(review.author)
      end
    end

    it 'contains the message from the notes of the review' do
      review.notes.each do |note|
        is_expected.to have_body_text note.note
      end
    end

    context 'when diff note' do
      let!(:notes) { create_list(:diff_note_on_merge_request, 3, review: review, project: project, author: review.author, noteable: merge_request) }

      it 'links to notes and discussions', :aggregate_failures do
        reply_note = create(:diff_note_on_merge_request, review: review, project: project, author: review.author, noteable: merge_request, in_reply_to: notes.first)

        review.notes.each do |note|
          # Text part
          expect(subject.text_part.body.raw_source).to include(
            project_merge_request_url(project, merge_request, anchor: "note_#{note.id}")
          )

          if note == reply_note
            expect(subject.text_part.body.raw_source).to include("commented on a discussion on #{note.discussion.file_path}")
          else
            expect(subject.text_part.body.raw_source).to include("started a new discussion on #{note.discussion.file_path}")
          end
        end
      end

      it 'includes only one link to the highlighted_diff_email' do
        expect(subject.html_part.body.raw_source).to include('assets/mailers/highlighted_diff_email').once
      end

      it 'avoids N+1 cached queries when rendering html', :use_sql_query_cache, :request_store do
        control = ActiveRecord::QueryRecorder.new(query_recorder_debug: true, skip_cached: false) do
          subject.html_part
        end

        create_list(:diff_note_on_merge_request, 3, review: review, project: project, author: review.author, noteable: merge_request)

        expect do
          described_class.new_review_email(recipient.id, review.id).html_part
        end.not_to exceed_all_query_limit(control)
      end

      it 'avoids N+1 cached queries when rendering text', :use_sql_query_cache, :request_store do
        control = ActiveRecord::QueryRecorder.new(query_recorder_debug: true, skip_cached: false) do
          subject.text_part
        end

        create_list(:diff_note_on_merge_request, 3, review: review, project: project, author: review.author, noteable: merge_request)

        expect do
          described_class.new_review_email(recipient.id, review.id).text_part
        end.not_to exceed_all_query_limit(control)
      end
    end

    it 'contains review author name' do
      is_expected.to have_body_text review.author_name
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject "Re: #{project.name} | #{merge_request.title} (#{merge_request.to_reference})"

        is_expected.to have_body_text project_merge_request_path(project, merge_request)
      end
    end
  end

  describe 'rate limiting', :freeze_time, :clean_gitlab_redis_rate_limiting do
    let(:recipient) { issue.assignees.first }

    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
        .and_return(notification_emails: { threshold: 1, interval: 1.minute })
    end

    it 'logs a message, stops sending notifications, and notifies the user of the rate limit only once', :aggregate_failures do
      expect(Gitlab::AppLogger).to receive(:info).with(
        event: 'notification_emails_rate_limited',
        user_id: recipient.id,
        project_id: issue.project_id,
        group_id: nil
      )

      perform_enqueued_jobs do
        3.times { described_class.new_issue_email(recipient.id, issue.id).deliver }
      end

      expect(ActionMailer::Base.deliveries.count).to eq(2)

      allowed_notification, rate_limit_notification = ActionMailer::Base.deliveries

      expect(allowed_notification).to have_referable_subject(issue)
      expect(rate_limit_notification.to).to contain_exactly(recipient.notification_email)
      expect(rate_limit_notification).to have_subject(/Notifications temporarily disabled/)
    end
  end
end
