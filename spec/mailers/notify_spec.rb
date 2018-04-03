require 'spec_helper'
require 'email_spec'

describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include RepoHelpers

  include_context 'gitlab email notification'

  set(:user) { create(:user) }
  set(:current_user) { create(:user, email: "current@email.com") }
  set(:assignee) { create(:user, email: 'assignee@example.com', name: 'John Doe') }

  set(:merge_request) do
    create(:merge_request, source_project: project,
                           target_project: project,
                           author: current_user,
                           assignee: assignee,
                           description: 'Awesome description')
  end

  set(:issue) do
    create(:issue, author: current_user,
                   assignees: [assignee],
                   project: project,
                   description: 'My awesome description!')
  end

  def have_referable_subject(referable, reply: false)
    prefix = referable.project ? "#{referable.project.name} | " : ''
    prefix.prepend('Re: ') if reply

    suffix = "#{referable.title} (#{referable.to_reference})"

    have_subject [prefix, suffix].compact.join
  end

  context 'for a project' do
    shared_examples 'an assignee email' do
      it 'is sent to the assignee as the author' do
        sender = subject.header[:from].addrs.first

        aggregate_failures do
          expect(sender.display_name).to eq(current_user.name)
          expect(sender.address).to eq(gitlab_sender)
          expect(subject).to deliver_to(assignee.email)
        end
      end
    end

    context 'for issues' do
      describe 'that are new' do
        subject { described_class.new_issue_email(issue.assignees.first.id, issue.id) }

        it_behaves_like 'an assignee email'
        it_behaves_like 'an email starting a new thread with reply-by-email enabled' do
          let(:model) { issue }
        end
        it_behaves_like 'it should show Gmail Actions View Issue link'
        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue)
            is_expected.to have_body_text(project_issue_path(project, issue))
          end
        end

        it 'contains the description' do
          is_expected.to have_html_escaped_body_text issue.description
        end

        it 'does not add a reason header' do
          is_expected.not_to have_header('X-GitLab-NotificationReason', /.+/)
        end

        context 'when sent with a reason' do
          subject { described_class.new_issue_email(issue.assignees.first.id, issue.id, NotificationReason::ASSIGNED) }

          it 'includes the reason in a header' do
            is_expected.to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
          end
        end

        context 'when enabled email_author_in_body' do
          before do
            stub_application_setting(email_author_in_body: true)
          end

          it 'contains a link to note author' do
            is_expected.to have_html_escaped_body_text(issue.author_name)
            is_expected.to have_body_text 'created an issue:'
          end
        end
      end

      describe 'that are reassigned' do
        let(:previous_assignee) { create(:user, name: 'Previous Assignee') }
        subject { described_class.reassigned_issue_email(recipient.id, issue.id, [previous_assignee.id], current_user.id) }

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { issue }
        end
        it_behaves_like 'it should show Gmail Actions View Issue link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(current_user.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_html_escaped_body_text(previous_assignee.name)
            is_expected.to have_html_escaped_body_text(assignee.name)
            is_expected.to have_body_text(project_issue_path(project, issue))
          end
        end

        context 'when sent with a reason' do
          subject { described_class.reassigned_issue_email(recipient.id, issue.id, [previous_assignee.id], current_user.id, NotificationReason::ASSIGNED) }

          it 'includes the reason in a header' do
            is_expected.to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
          end
        end
      end

      describe 'that have been relabeled' do
        subject { described_class.relabeled_issue_email(recipient.id, issue.id, %w[foo bar baz], current_user.id) }

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { issue }
        end
        it_behaves_like 'it should show Gmail Actions View Issue link'
        it_behaves_like 'a user cannot unsubscribe through footer link'
        it_behaves_like 'an email with a labels subscriptions link in its footer'

        it 'is sent as the author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(current_user.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text('foo, bar, and baz')
            is_expected.to have_body_text(project_issue_path(project, issue))
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

      describe 'status changed' do
        let(:status) { 'closed' }
        subject { described_class.issue_status_changed_email(recipient.id, issue.id, status, current_user.id) }

        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { issue }
        end
        it_behaves_like 'it should show Gmail Actions View Issue link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(current_user.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text(status)
            is_expected.to have_html_escaped_body_text(current_user.name)
            is_expected.to have_body_text(project_issue_path project, issue)
          end
        end
      end

      describe 'moved to another project' do
        let(:new_issue) { create(:issue) }
        subject { described_class.issue_moved_email(recipient, issue, new_issue, current_user) }

        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { issue }
        end
        it_behaves_like 'it should show Gmail Actions View Issue link'
        it_behaves_like 'an unsubscribeable thread'

        it 'contains description about action taken' do
          is_expected.to have_body_text 'Issue was moved to another project'
        end

        it 'has the correct subject and body' do
          new_issue_url = project_issue_path(new_issue.project, new_issue)

          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text(new_issue_url)
            is_expected.to have_body_text(project_issue_path(project, issue))
          end
        end
      end
    end

    context 'for merge requests' do
      describe 'that are new' do
        subject { described_class.new_merge_request_email(merge_request.assignee_id, merge_request.id) }

        it_behaves_like 'an assignee email'
        it_behaves_like 'an email starting a new thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request)
            is_expected.to have_body_text(project_merge_request_path(project, merge_request))
            is_expected.to have_body_text(merge_request.source_branch)
            is_expected.to have_body_text(merge_request.target_branch)
          end
        end

        it 'contains the description' do
          is_expected.to have_html_escaped_body_text merge_request.description
        end

        context 'when sent with a reason' do
          subject { described_class.new_merge_request_email(merge_request.assignee_id, merge_request.id, NotificationReason::ASSIGNED) }

          it 'includes the reason in a header' do
            is_expected.to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
          end
        end

        context 'when enabled email_author_in_body' do
          before do
            stub_application_setting(email_author_in_body: true)
          end

          it 'contains a link to note author' do
            is_expected.to have_html_escaped_body_text merge_request.author_name
            is_expected.to have_body_text 'created a merge request:'
          end
        end
      end

      describe 'that are reassigned' do
        let(:previous_assignee) { create(:user, name: 'Previous Assignee') }
        subject { described_class.reassigned_merge_request_email(recipient.id, merge_request.id, previous_assignee.id, current_user.id) }

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like "an unsubscribeable thread"

        it 'is sent as the author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(current_user.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_html_escaped_body_text(previous_assignee.name)
            is_expected.to have_body_text(project_merge_request_path(project, merge_request))
            is_expected.to have_html_escaped_body_text(assignee.name)
          end
        end

        context 'when sent with a reason' do
          subject { described_class.reassigned_merge_request_email(recipient.id, merge_request.id, previous_assignee.id, current_user.id, NotificationReason::ASSIGNED) }

          it 'includes the reason in a header' do
            is_expected.to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
          end

          it 'includes the reason in the footer' do
            text = EmailsHelper.instance_method(:notification_reason_text).bind(self).call(NotificationReason::ASSIGNED)
            is_expected.to have_body_text(text)

            new_subject = described_class.reassigned_merge_request_email(recipient.id, merge_request.id, previous_assignee.id, current_user.id, NotificationReason::MENTIONED)
            text = EmailsHelper.instance_method(:notification_reason_text).bind(self).call(NotificationReason::MENTIONED)
            expect(new_subject).to have_body_text(text)

            new_subject = described_class.reassigned_merge_request_email(recipient.id, merge_request.id, previous_assignee.id, current_user.id, nil)
            text = EmailsHelper.instance_method(:notification_reason_text).bind(self).call(nil)
            expect(new_subject).to have_body_text(text)
          end
        end
      end

      describe 'that are new with a description' do
        subject { described_class.new_merge_request_email(merge_request.assignee_id, merge_request.id) }

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like "an unsubscribeable thread"

        it 'contains the description' do
          is_expected.to have_html_escaped_body_text merge_request.description
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

        it 'is sent as the author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(current_user.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject and body' do
          is_expected.to have_referable_subject(merge_request, reply: true)
          is_expected.to have_body_text('foo, bar, and baz')
          is_expected.to have_body_text(project_merge_request_path(project, merge_request))
        end
      end

      describe 'status changed' do
        let(:status) { 'reopened' }
        subject { described_class.merge_request_status_email(recipient.id, merge_request.id, status, current_user.id) }

        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(current_user.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text(status)
            is_expected.to have_html_escaped_body_text(current_user.name)
            is_expected.to have_body_text(project_merge_request_path(project, merge_request))
          end
        end
      end

      describe 'that are merged' do
        let(:merge_author) { create(:user) }
        subject { described_class.merged_merge_request_email(recipient.id, merge_request.id, merge_author.id) }

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the merge author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(merge_author.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text('merged')
            is_expected.to have_body_text(project_merge_request_path(project, merge_request))
          end
        end
      end

      describe 'that have new commits' do
        let(:push_user) { create(:user) }

        subject do
          described_class.push_to_merge_request_email(recipient.id, merge_request.id, push_user.id, new_commits: merge_request.commits)
        end

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the push user' do
          sender = subject.header[:from].addrs[0]

          expect(sender.display_name).to eq(push_user.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text("#{push_user.name} pushed new commits")
            is_expected.to have_body_text(project_merge_request_path(project, merge_request))
          end
        end
      end
    end

    context 'for issue notes' do
      let(:host) { Gitlab.config.gitlab.host }

      context 'in discussion' do
        set(:first_note) { create(:discussion_note_on_issue) }
        set(:second_note) { create(:discussion_note_on_issue, in_reply_to: first_note) }
        set(:third_note) { create(:discussion_note_on_issue, in_reply_to: second_note) }

        subject { described_class.note_issue_email(recipient.id, third_note.id) }

        it 'has In-Reply-To header pointing to previous note in discussion' do
          expect(subject.header['In-Reply-To'].message_ids).to eq(["note_#{second_note.id}@#{host}"])
        end

        it 'has References header including the notes and issue of the discussion' do
          expect(subject.header['References'].message_ids).to include("issue_#{first_note.noteable.id}@#{host}",
                                                                   "note_#{first_note.id}@#{host}",
                                                                   "note_#{second_note.id}@#{host}")
        end

        it 'has X-GitLab-Discussion-ID header' do
          expect(subject.header['X-GitLab-Discussion-ID'].value).to eq(third_note.discussion.id)
        end
      end

      context 'individual issue comments' do
        set(:note) { create(:note_on_issue) }

        subject { described_class.note_issue_email(recipient.id, note.id) }

        it 'has In-Reply-To header pointing to the issue' do
          expect(subject.header['In-Reply-To'].message_ids).to eq(["issue_#{note.noteable.id}@#{host}"])
        end

        it 'has References header including the notes and issue of the discussion' do
          expect(subject.header['References'].message_ids).to include("issue_#{note.noteable.id}@#{host}")
        end
      end
    end

    context 'for snippet notes' do
      let(:project_snippet) { create(:project_snippet, project: project) }
      let(:project_snippet_note) { create(:note_on_project_snippet, project: project, noteable: project_snippet) }

      subject { described_class.note_snippet_email(project_snippet_note.author_id, project_snippet_note.id) }

      it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
        let(:model) { project_snippet }
      end
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has the correct subject and body' do
        is_expected.to have_referable_subject(project_snippet, reply: true)
        is_expected.to have_html_escaped_body_text project_snippet_note.note
      end
    end

    describe 'project was moved' do
      subject { described_class.project_was_moved_email(project.id, user.id, "gitlab/gitlab") }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'has the correct subject and body' do
        is_expected.to have_subject("#{project.name} | Project was moved")
        is_expected.to have_html_escaped_body_text project.full_name
        is_expected.to have_body_text(project.ssh_url_to_repo)
      end
    end

    describe 'project access requested' do
      let(:project) do
        create(:project, :public, :access_requestable) do |project|
          project.add_master(project.owner)
        end
      end

      let(:project_member) do
        project.request_access(user)
        project.requesters.find_by(user_id: user.id)
      end
      subject { described_class.member_access_requested_email('project', project_member.id, recipient.notification_email) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        to_emails = subject.header[:to].addrs.map(&:address)
        expect(to_emails).to eq([recipient.notification_email])

        is_expected.to have_subject "Request to join the #{project.full_name} project"
        is_expected.to have_html_escaped_body_text project.full_name
        is_expected.to have_body_text project_project_members_url(project)
        is_expected.to have_body_text project_member.human_access
      end
    end

    describe 'project access denied' do
      let(:project) { create(:project, :public, :access_requestable) }
      let(:project_member) do
        project.request_access(user)
        project.requesters.find_by(user_id: user.id)
      end
      subject { described_class.member_access_denied_email('project', project.id, user.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{project.full_name} project was denied"
        is_expected.to have_html_escaped_body_text project.full_name
        is_expected.to have_body_text project.web_url
      end
    end

    describe 'project access changed' do
      let(:owner) { create(:user, name: "Chang O'Keefe") }
      let(:project) { create(:project, :public, :access_requestable, namespace: owner.namespace) }
      let(:project_member) { create(:project_member, project: project, user: user) }
      subject { described_class.member_access_granted_email('project', project_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{project.full_name} project was granted"
        is_expected.to have_html_escaped_body_text project.full_name
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.human_access
      end
    end

    def invite_to_project(project, inviter:)
      create(
        :project_member,
        :developer,
        project: project,
        invite_token: '1234',
        invite_email: 'toto@example.com',
        user: nil,
        created_by: inviter
      )
    end

    describe 'project invitation' do
      let(:master) { create(:user).tap { |u| project.add_master(u) } }
      let(:project_member) { invite_to_project(project, inviter: master) }

      subject { described_class.member_invited_email('project', project_member.id, project_member.invite_token) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Invitation to join the #{project.full_name} project"
        is_expected.to have_html_escaped_body_text project.full_name
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.human_access
        is_expected.to have_body_text project_member.invite_token
      end
    end

    describe 'project invitation accepted' do
      let(:invited_user) { create(:user, name: 'invited user') }
      let(:master) { create(:user).tap { |u| project.add_master(u) } }
      let(:project_member) do
        invitee = invite_to_project(project, inviter: master)
        invitee.accept_invite!(invited_user)
        invitee
      end

      subject { described_class.member_invite_accepted_email('project', project_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation accepted'
        is_expected.to have_html_escaped_body_text project.full_name
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.invite_email
        is_expected.to have_html_escaped_body_text invited_user.name
      end
    end

    describe 'project invitation declined' do
      let(:master) { create(:user).tap { |u| project.add_master(u) } }
      let(:project_member) do
        invitee = invite_to_project(project, inviter: master)
        invitee.decline_invite!
        invitee
      end

      subject { described_class.member_invite_declined_email('project', project.id, project_member.invite_email, master.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation declined'
        is_expected.to have_html_escaped_body_text project.full_name
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.invite_email
      end
    end

    context 'items that are noteable, the email for a note' do
      let(:note_author) { create(:user, name: 'author_name') }
      let(:note) { create(:note, project: project, author: note_author) }

      before do
        allow(Note).to receive(:find).with(note.id).and_return(note)
      end

      shared_examples 'a note email' do
        it_behaves_like 'it should have Gmail Actions links'

        it 'is sent to the given recipient as the author' do
          sender = subject.header[:from].addrs[0]

          aggregate_failures do
            expect(sender.display_name).to eq(note_author.name)
            expect(sender.address).to eq(gitlab_sender)
            expect(subject).to deliver_to(recipient.notification_email)
          end
        end

        it 'contains the message from the note' do
          is_expected.to have_html_escaped_body_text note.note
        end

        it 'does not contain note author' do
          is_expected.not_to have_body_text note.author_name
        end

        context 'when enabled email_author_in_body' do
          before do
            stub_application_setting(email_author_in_body: true)
          end

          it 'contains a link to note author' do
            is_expected.to have_html_escaped_body_text note.author_name
          end
        end
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

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text note_on_merge_request_path
          end
        end
      end

      describe 'on an issue' do
        let(:note_on_issue_path) { project_issue_path(project, issue, anchor: "note_#{note.id}") }

        before do
          allow(note).to receive(:noteable).and_return(issue)
        end

        subject { described_class.note_issue_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { issue }
        end
        it_behaves_like 'it should show Gmail Actions View Issue link'
        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text(note_on_issue_path)
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

        it 'is sent to the given recipient as the author' do
          sender = subject.header[:from].addrs[0]

          aggregate_failures do
            expect(sender.display_name).to eq(note_author.name)
            expect(sender.address).to eq(gitlab_sender)
            expect(subject).to deliver_to(recipient.notification_email)
          end
        end

        it 'contains the message from the note' do
          is_expected.to have_body_text note.note
        end

        it 'contains an introduction' do
          is_expected.to have_body_text 'started a new discussion'
        end

        context 'when a comment on an existing discussion' do
          let!(:second_note) { create(model, author: note_author, noteable: nil, in_reply_to: note) }

          it 'contains an introduction' do
            is_expected.to have_body_text 'commented on a'
          end
        end
      end

      describe 'on a commit' do
        let(:commit) { project.commit }
        let(:note) { create(:discussion_note_on_commit, commit_id: commit.id, project: project, author: note_author) }

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

        it 'has the correct subject' do
          is_expected.to have_subject "Re: #{project.name} | #{commit.title} (#{commit.short_id})"
        end

        it 'contains a link to the commit' do
          is_expected.to have_body_text commit.short_id
        end
      end

      describe 'on a merge request' do
        let(:note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project, author: note_author) }
        let(:note_on_merge_request_path) { project_merge_request_path(project, merge_request, anchor: "note_#{note.id}") }

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

        it 'has the correct subject' do
          is_expected.to have_referable_subject(merge_request, reply: true)
        end

        it 'contains a link to the merge request note' do
          is_expected.to have_body_text note_on_merge_request_path
        end
      end

      describe 'on an issue' do
        let(:note) { create(:discussion_note_on_issue, noteable: issue, project: project, author: note_author) }
        let(:note_on_issue_path) { project_issue_path(project, issue, anchor: "note_#{note.id}") }

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

      shared_examples 'an email for a note on a diff discussion' do  |model|
        let(:note) { create(model, author: note_author) }

        context 'when note is on image' do
          before do
            allow_any_instance_of(DiffDiscussion).to receive(:on_image?).and_return(true)
          end

          it 'does not include diffs with character-level highlighting' do
            is_expected.not_to have_body_text '<span class="p">}</span></span>'
          end

          it 'ends the intro with a dot' do
            is_expected.to have_body_text "#{note.diff_file.file_path}</a>."
          end
        end

        it 'ends the intro with a colon' do
          is_expected.to have_body_text "#{note.diff_file.file_path}</a>:"
        end

        it 'includes diffs with character-level highlighting' do
          is_expected.to have_body_text '<span class="p">}</span></span>'
        end

        it 'contains a link to the diff file' do
          is_expected.to have_body_text note.diff_file.file_path
        end

        it_behaves_like 'it should have Gmail Actions links'

        it 'is sent to the given recipient as the author' do
          sender = subject.header[:from].addrs[0]

          aggregate_failures do
            expect(sender.display_name).to eq(note_author.name)
            expect(sender.address).to eq(gitlab_sender)
            expect(subject).to deliver_to(recipient.notification_email)
          end
        end

        it 'contains the message from the note' do
          is_expected.to have_html_escaped_body_text note.note
        end

        it 'contains an introduction' do
          is_expected.to have_body_text 'started a new discussion on'
        end

        context 'when a comment on an existing discussion' do
          let!(:second_note) { create(model, author: note_author, noteable: nil, in_reply_to: note) }

          it 'contains an introduction' do
            is_expected.to have_body_text 'commented on a discussion on'
          end
        end
      end

      describe 'on a commit' do
        let(:commit) { project.commit }
        let(:note) { create(:diff_note_on_commit) }

        subject { described_class.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'an email for a note on a diff discussion', :diff_note_on_commit
        it_behaves_like 'it should show Gmail Actions View Commit link'
        it_behaves_like 'a user cannot unsubscribe through footer link'
      end

      describe 'on a merge request' do
        let(:note) { create(:diff_note_on_merge_request) }

        subject { described_class.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'an email for a note on a diff discussion', :diff_note_on_merge_request
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'
      end
    end
  end

  context 'for a group' do
    set(:group) { create(:group) }

    describe 'group access requested' do
      let(:group) { create(:group, :public, :access_requestable) }
      let(:group_member) do
        group.request_access(user)
        group.requesters.find_by(user_id: user.id)
      end
      subject { described_class.member_access_requested_email('group', group_member.id, recipient.notification_email) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        to_emails = subject.header[:to].addrs.map(&:address)
        expect(to_emails).to eq([recipient.notification_email])

        is_expected.to have_subject "Request to join the #{group.name} group"
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group_group_members_url(group)
        is_expected.to have_body_text group_member.human_access
      end
    end

    describe 'group access denied' do
      let(:group_member) do
        group.request_access(user)
        group.requesters.find_by(user_id: user.id)
      end
      subject { described_class.member_access_denied_email('group', group.id, user.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{group.name} group was denied"
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
      end
    end

    describe 'group access changed' do
      let(:group_member) { create(:group_member, group: group, user: user) }

      subject { described_class.member_access_granted_email('group', group_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{group.name} group was granted"
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.human_access
      end
    end

    def invite_to_group(group, inviter:)
      create(
        :group_member,
        :developer,
        group: group,
        invite_token: '1234',
        invite_email: 'toto@example.com',
        user: nil,
        created_by: inviter
      )
    end

    describe 'group invitation' do
      let(:owner) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::OWNER) } }
      let(:group_member) { invite_to_group(group, inviter: owner) }

      subject { described_class.member_invited_email('group', group_member.id, group_member.invite_token) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Invitation to join the #{group.name} group"
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.human_access
        is_expected.to have_body_text group_member.invite_token
      end
    end

    describe 'group invitation accepted' do
      let(:invited_user) { create(:user, name: 'invited user') }
      let(:owner) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::OWNER) } }
      let(:group_member) do
        invitee = invite_to_group(group, inviter: owner)
        invitee.accept_invite!(invited_user)
        invitee
      end

      subject { described_class.member_invite_accepted_email('group', group_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation accepted'
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.invite_email
        is_expected.to have_html_escaped_body_text invited_user.name
      end
    end

    describe 'group invitation declined' do
      let(:owner) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::OWNER) } }
      let(:group_member) do
        invitee = invite_to_group(group, inviter: owner)
        invitee.decline_invite!
        invitee
      end

      subject { described_class.member_invite_declined_email('group', group.id, group_member.invite_email, owner.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation declined'
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.invite_email
      end
    end
  end

  describe 'confirmation if email changed' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user, email: 'old-email@mail.com') }

    before do
      stub_config_setting(email_subject_suffix: 'A Nice Suffix')
      perform_enqueued_jobs do
        user.email = "new-email@mail.com"
        user.save
      end
    end

    subject { ActionMailer::Base.deliveries.last }

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

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
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

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
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

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
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

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
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

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
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

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
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

  describe 'mirror was hard failed' do
    let(:project) { create(:project, :mirror, :import_hard_failed) }

    subject { described_class.mirror_was_hard_failed_email(project.id, user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Repository mirroring paused")
      is_expected.to have_html_escaped_body_text(project.full_path)
    end
  end

  describe 'mirror user changed' do
    let(:mirror_user) { create(:user) }
    let(:project) { create(:project, :mirror, mirror_user_id: mirror_user.id) }
    let(:new_mirror_user) { project.team.owners.first }

    subject { described_class.project_mirror_user_changed_email(new_mirror_user.id, mirror_user.name, project.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Mirror user changed")
      is_expected.to have_html_escaped_body_text(project.full_path)
    end
  end

  describe 'admin notification' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }

    subject { @email = described_class.send_admin_notification(user.id, 'Admin announcement', 'Text') }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq("GitLab")
      expect(sender.address).to eq(gitlab_sender)
    end

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

  describe 'HTML emails setting' do
    let(:multipart_mail) { described_class.project_was_moved_email(project.id, user.id, "gitlab/gitlab") }

    context 'when disabled' do
      it 'only sends the text template' do
        stub_application_setting(html_emails_enabled: false)

        EmailTemplateInterceptor.delivering_email(multipart_mail)

        expect(multipart_mail).to have_part_with('text/plain')
        expect(multipart_mail).not_to have_part_with('text/html')
      end
    end

    context 'when enabled' do
      it 'sends a multipart message' do
        stub_application_setting(html_emails_enabled: true)

        EmailTemplateInterceptor.delivering_email(multipart_mail)

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

    subject { described_class.note_personal_snippet_email(personal_snippet_note.author_id, personal_snippet_note.id) }

    it_behaves_like 'a user cannot unsubscribe through footer link'

    it 'has the correct subject and body' do
      is_expected.to have_referable_subject(personal_snippet, reply: true)
      is_expected.to have_html_escaped_body_text personal_snippet_note.note
    end
  end
end
