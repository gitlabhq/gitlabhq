require 'spec_helper'
require 'email_spec'

describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include RepoHelpers

  new_user_address = 'newguy@example.com'

  let(:gitlab_sender_display_name) { Gitlab.config.gitlab.email_display_name }
  let(:gitlab_sender) { Gitlab.config.gitlab.email_from }
  let(:gitlab_sender_reply_to) { Gitlab.config.gitlab.email_reply_to }
  let(:recipient) { create(:user, email: 'recipient@example.com') }
  let(:project) { create(:project) }

  before(:each) do
    ActionMailer::Base.deliveries.clear
    email = recipient.emails.create(email: "notifications@example.com")
    recipient.update_attribute(:notification_email, email.email)
  end

  shared_examples 'a multiple recipients email' do
    it 'is sent to the given recipient' do
      is_expected.to deliver_to recipient.notification_email
    end
  end

  shared_examples 'an email sent from GitLab' do
    it 'is sent from GitLab' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(gitlab_sender_display_name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'has a Reply-To address' do
      reply_to = subject.header[:reply_to].addresses
      expect(reply_to).to eq([gitlab_sender_reply_to])
    end
  end

  shared_examples 'an email starting a new thread' do |message_id_prefix|
    it 'has a discussion identifier' do
      is_expected.to have_header 'Message-ID',  /<#{message_id_prefix}(.*)@#{Gitlab.config.gitlab.host}>/
      is_expected.to have_header 'X-GitLab-Project', /#{project.name}/
    end
  end

  shared_examples 'an answer to an existing thread' do |thread_id_prefix|
    it 'has a subject that begins with Re: ' do
      is_expected.to have_subject /^Re: /
    end

    it 'has headers that reference an existing thread' do
      is_expected.to have_header 'Message-ID',  /<(.*)@#{Gitlab.config.gitlab.host}>/
      is_expected.to have_header 'References',  /<#{thread_id_prefix}(.*)@#{Gitlab.config.gitlab.host}>/
      is_expected.to have_header 'In-Reply-To', /<#{thread_id_prefix}(.*)@#{Gitlab.config.gitlab.host}>/
      is_expected.to have_header 'X-GitLab-Project', /#{project.name}/
    end
  end

  shared_examples 'a new user email' do |user_email, site_path|
    it 'is sent to the new user' do
      is_expected.to deliver_to user_email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^Account was created for you$/i
    end

    it 'contains the new user\'s login name' do
      is_expected.to have_body_text /#{user_email}/
    end

    it 'includes a link to the site' do
      is_expected.to have_body_text /#{site_path}/
    end
  end

  describe 'for new users, the email' do
    let(:example_site_path) { root_path }
    let(:new_user) { create(:user, email: new_user_address, created_by_id: 1) }

    token = 'kETLwRaayvigPq_x3SNM'

    subject { Notify.new_user_email(new_user.id, token) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'a new user email', new_user_address

    it 'contains the password text' do
      is_expected.to have_body_text /Click here to set your password/
    end

    it 'includes a link for user to set password' do
      params = "reset_password_token=#{token}"
      is_expected.to have_body_text(
        %r{http://localhost(:\d+)?/users/password/edit\?#{params}}
      )
    end

    it 'explains the reset link expiration' do
      is_expected.to have_body_text(/This link is valid for \d+ (hours?|days?)/)
      is_expected.to have_body_text(new_user_password_url)
      is_expected.to have_body_text(/\?user_email=.*%40.*/)
    end
  end


  describe 'for users that signed up, the email' do
    let(:example_site_path) { root_path }
    let(:new_user) { create(:user, email: new_user_address, password: "securePassword") }

    subject { Notify.new_user_email(new_user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'a new user email', new_user_address

    it 'should not contain the new user\'s password' do
      is_expected.not_to have_body_text /password/
    end
  end

  describe 'user added ssh key' do
    let(:key) { create(:personal_key) }

    subject { Notify.new_ssh_key_email(key.id) }

    it_behaves_like 'an email sent from GitLab'

    it 'is sent to the new user' do
      is_expected.to deliver_to key.user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^SSH key was added to your account$/i
    end

    it 'contains the new ssh key title' do
      is_expected.to have_body_text /#{key.title}/
    end

    it 'includes a link to ssh keys page' do
      is_expected.to have_body_text /#{profile_keys_path}/
    end
  end

  describe 'user added email' do
    let(:email) { create(:email) }

    subject { Notify.new_email_email(email.id) }

    it 'is sent to the new user' do
      is_expected.to deliver_to email.user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject /^Email was added to your account$/i
    end

    it 'contains the new email address' do
      is_expected.to have_body_text /#{email.email}/
    end

    it 'includes a link to emails page' do
      is_expected.to have_body_text /#{profile_emails_path}/
    end
  end

  context 'for a project' do
    describe 'items that are assignable, the email' do
      let(:current_user) { create(:user, email: "current@email.com") }
      let(:assignee) { create(:user, email: 'assignee@example.com') }
      let(:previous_assignee) { create(:user, name: 'Previous Assignee') }

      shared_examples 'an assignee email' do
        it 'is sent as the author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(current_user.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'is sent to the assignee' do
          is_expected.to deliver_to assignee.email
        end
      end

      context 'for issues' do
        let(:issue) { create(:issue, author: current_user, assignee: assignee, project: project) }
        let(:issue_with_description) { create(:issue, author: current_user, assignee: assignee, project: project, description: FFaker::Lorem.sentence) }

        describe 'that are new' do
          subject { Notify.new_issue_email(issue.assignee_id, issue.id) }

          it_behaves_like 'an assignee email'
          it_behaves_like 'an email starting a new thread', 'issue'

          it 'has the correct subject' do
            is_expected.to have_subject /#{project.name} \| #{issue.title} \(##{issue.iid}\)/
          end

          it 'contains a link to the new issue' do
            is_expected.to have_body_text /#{namespace_project_issue_path project.namespace, project, issue}/
          end
        end

        describe 'that are new with a description' do
          subject { Notify.new_issue_email(issue_with_description.assignee_id, issue_with_description.id) }

          it 'contains the description' do
            is_expected.to have_body_text /#{issue_with_description.description}/
          end
        end

        describe 'that have been reassigned' do
          subject { Notify.reassigned_issue_email(recipient.id, issue.id, previous_assignee.id, current_user) }

          it_behaves_like 'a multiple recipients email'
          it_behaves_like 'an answer to an existing thread', 'issue'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject' do
            is_expected.to have_subject /#{issue.title} \(##{issue.iid}\)/
          end

          it 'contains the name of the previous assignee' do
            is_expected.to have_body_text /#{previous_assignee.name}/
          end

          it 'contains the name of the new assignee' do
            is_expected.to have_body_text /#{assignee.name}/
          end

          it 'contains a link to the issue' do
            is_expected.to have_body_text /#{namespace_project_issue_path project.namespace, project, issue}/
          end
        end

        describe 'status changed' do
          let(:status) { 'closed' }
          subject { Notify.issue_status_changed_email(recipient.id, issue.id, status, current_user) }

          it_behaves_like 'an answer to an existing thread', 'issue'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject' do
            is_expected.to have_subject /#{issue.title} \(##{issue.iid}\)/i
          end

          it 'contains the new status' do
            is_expected.to have_body_text /#{status}/i
          end

          it 'contains the user name' do
            is_expected.to have_body_text /#{current_user.name}/i
          end

          it 'contains a link to the issue' do
            is_expected.to have_body_text /#{namespace_project_issue_path project.namespace, project, issue}/
          end
        end

      end

      context 'for merge requests' do
        let(:merge_author) { create(:user) }
        let(:merge_request) { create(:merge_request, author: current_user, assignee: assignee, source_project: project, target_project: project) }
        let(:merge_request_with_description) { create(:merge_request, author: current_user, assignee: assignee, source_project: project, target_project: project, description: FFaker::Lorem.sentence) }

        describe 'that are new' do
          subject { Notify.new_merge_request_email(merge_request.assignee_id, merge_request.id) }

          it_behaves_like 'an assignee email'
          it_behaves_like 'an email starting a new thread', 'merge_request'

          it 'has the correct subject' do
            is_expected.to have_subject /#{merge_request.title} \(##{merge_request.iid}\)/
          end

          it 'contains a link to the new merge request' do
            is_expected.to have_body_text /#{namespace_project_merge_request_path(project.namespace, project, merge_request)}/
          end

          it 'contains the source branch for the merge request' do
            is_expected.to have_body_text /#{merge_request.source_branch}/
          end

          it 'contains the target branch for the merge request' do
            is_expected.to have_body_text /#{merge_request.target_branch}/
          end

          it 'has the correct message-id set' do
            is_expected.to have_header 'Message-ID', "<merge_request_#{merge_request.id}@#{Gitlab.config.gitlab.host}>"
          end
        end

        describe 'that are new with a description' do
          subject { Notify.new_merge_request_email(merge_request_with_description.assignee_id, merge_request_with_description.id) }

          it 'contains the description' do
            is_expected.to have_body_text /#{merge_request_with_description.description}/
          end
        end

        describe 'that are reassigned' do
          subject { Notify.reassigned_merge_request_email(recipient.id, merge_request.id, previous_assignee.id, current_user.id) }

          it_behaves_like 'a multiple recipients email'
          it_behaves_like 'an answer to an existing thread', 'merge_request'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject' do
            is_expected.to have_subject /#{merge_request.title} \(##{merge_request.iid}\)/
          end

          it 'contains the name of the previous assignee' do
            is_expected.to have_body_text /#{previous_assignee.name}/
          end

          it 'contains the name of the new assignee' do
            is_expected.to have_body_text /#{assignee.name}/
          end

          it 'contains a link to the merge request' do
            is_expected.to have_body_text /#{namespace_project_merge_request_path project.namespace, project, merge_request}/
          end
        end

        describe 'status changed' do
          let(:status) { 'reopened' }
          subject { Notify.merge_request_status_email(recipient.id, merge_request.id, status, current_user) }

          it_behaves_like 'an answer to an existing thread', 'merge_request'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject' do
            is_expected.to have_subject /#{merge_request.title} \(##{merge_request.iid}\)/i
          end

          it 'contains the new status' do
            is_expected.to have_body_text /#{status}/i
          end

          it 'contains the user name' do
            is_expected.to have_body_text /#{current_user.name}/i
          end

          it 'contains a link to the merge request' do
            is_expected.to have_body_text /#{namespace_project_merge_request_path project.namespace, project, merge_request}/
          end
        end

        describe 'that are merged' do
          subject { Notify.merged_merge_request_email(recipient.id, merge_request.id, merge_author.id) }

          it_behaves_like 'a multiple recipients email'
          it_behaves_like 'an answer to an existing thread', 'merge_request'

          it 'is sent as the merge author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(merge_author.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject' do
            is_expected.to have_subject /#{merge_request.title} \(##{merge_request.iid}\)/
          end

          it 'contains the new status' do
            is_expected.to have_body_text /merged/i
          end

          it 'contains a link to the merge request' do
            is_expected.to have_body_text /#{namespace_project_merge_request_path project.namespace, project, merge_request}/
          end
        end
      end
    end

    describe 'project was moved' do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      subject { Notify.project_was_moved_email(project.id, user.id, "gitlab/gitlab") }

      it_behaves_like 'an email sent from GitLab'

      it 'has the correct subject' do
        is_expected.to have_subject /Project was moved/
      end

      it 'contains name of project' do
        is_expected.to have_body_text /#{project.name_with_namespace}/
      end

      it 'contains new user role' do
        is_expected.to have_body_text /#{project.ssh_url_to_repo}/
      end
    end

    describe 'project access changed' do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      let(:project_member) { create(:project_member, project: project, user: user) }
      subject { Notify.project_access_granted_email(project_member.id) }

      it_behaves_like 'an email sent from GitLab'

      it 'has the correct subject' do
        is_expected.to have_subject /Access to project was granted/
      end
      it 'contains name of project' do
        is_expected.to have_body_text /#{project.name}/
      end
      it 'contains new user role' do
        is_expected.to have_body_text /#{project_member.human_access}/
      end
    end

    context 'items that are noteable, the email for a note' do
      let(:note_author) { create(:user, name: 'author_name') }
      let(:note) { create(:note, project: project, author: note_author) }

      before :each do
        allow(Note).to receive(:find).with(note.id).and_return(note)
      end

      shared_examples 'a note email' do
        it 'is sent as the author' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(note_author.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'is sent to the given recipient' do
          is_expected.to deliver_to recipient.notification_email
        end

        it 'contains the message from the note' do
          is_expected.to have_body_text /#{note.note}/
        end
      end

      describe 'on a commit' do
        let(:commit) { project.commit }

        before(:each) { allow(note).to receive(:noteable).and_return(commit) }

        subject { Notify.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread', 'commits'

        it 'has the correct subject' do
          is_expected.to have_subject /#{commit.title} \(#{commit.short_id}\)/
        end

        it 'contains a link to the commit' do
          is_expected.to have_body_text commit.short_id
        end
      end

      describe 'on a merge request' do
        let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
        let(:note_on_merge_request_path) { namespace_project_merge_request_path(project.namespace, project, merge_request, anchor: "note_#{note.id}") }
        before(:each) { allow(note).to receive(:noteable).and_return(merge_request) }

        subject { Notify.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread', 'merge_request'

        it 'has the correct subject' do
          is_expected.to have_subject /#{merge_request.title} \(##{merge_request.iid}\)/
        end

        it 'contains a link to the merge request note' do
          is_expected.to have_body_text /#{note_on_merge_request_path}/
        end
      end

      describe 'on an issue' do
        let(:issue) { create(:issue, project: project) }
        let(:note_on_issue_path) { namespace_project_issue_path(project.namespace, project, issue, anchor: "note_#{note.id}") }
        before(:each) { allow(note).to receive(:noteable).and_return(issue) }

        subject { Notify.note_issue_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread', 'issue'

        it 'has the correct subject' do
          is_expected.to have_subject /#{issue.title} \(##{issue.iid}\)/
        end

        it 'contains a link to the issue note' do
          is_expected.to have_body_text /#{note_on_issue_path}/
        end
      end
    end
  end

  describe 'group access changed' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let(:membership) { create(:group_member, group: group, user: user) }

    subject { Notify.group_access_granted_email(membership.id) }

    it_behaves_like 'an email sent from GitLab'

    it 'has the correct subject' do
      is_expected.to have_subject /Access to group was granted/
    end

    it 'contains name of project' do
      is_expected.to have_body_text /#{group.name}/
    end

    it 'contains new user role' do
      is_expected.to have_body_text /#{membership.human_access}/
    end
  end

  describe 'confirmation if email changed' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user, email: 'old-email@mail.com') }

    before do
      user.email = "new-email@mail.com"
      user.save
    end

    subject { ActionMailer::Base.deliveries.last }

    it_behaves_like 'an email sent from GitLab'

    it 'is sent to the new user' do
      is_expected.to deliver_to 'new-email@mail.com'
    end

    it 'has the correct subject' do
      is_expected.to have_subject "Confirmation instructions"
    end

    it 'includes a link to the site' do
      is_expected.to have_body_text /#{example_site_path}/
    end
  end

  describe 'email on push for a created branch' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:tree_path) { namespace_project_tree_path(project.namespace, project, "master") }

    subject { Notify.repository_push_email(project.id, 'devs@company.name', author_id: user.id, ref: 'refs/heads/master', action: :create) }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'is sent to recipient' do
      is_expected.to deliver_to 'devs@company.name'
    end

    it 'has the correct subject' do
      is_expected.to have_subject /Pushed new branch master/
    end

    it 'contains a link to the branch' do
      is_expected.to have_body_text /#{tree_path}/
    end
  end

  describe 'email on push for a created tag' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:tree_path) { namespace_project_tree_path(project.namespace, project, "v1.0") }

    subject { Notify.repository_push_email(project.id, 'devs@company.name', author_id: user.id, ref: 'refs/tags/v1.0', action: :create) }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'is sent to recipient' do
      is_expected.to deliver_to 'devs@company.name'
    end

    it 'has the correct subject' do
      is_expected.to have_subject /Pushed new tag v1\.0/
    end

    it 'contains a link to the tag' do
      is_expected.to have_body_text /#{tree_path}/
    end
  end

  describe 'email on push for a deleted branch' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }

    subject { Notify.repository_push_email(project.id, 'devs@company.name', author_id: user.id, ref: 'refs/heads/master', action: :delete) }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'is sent to recipient' do
      is_expected.to deliver_to 'devs@company.name'
    end

    it 'has the correct subject' do
      is_expected.to have_subject /Deleted branch master/
    end
  end

  describe 'email on push for a deleted tag' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }

    subject { Notify.repository_push_email(project.id, 'devs@company.name', author_id: user.id, ref: 'refs/tags/v1.0', action: :delete) }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'is sent to recipient' do
      is_expected.to deliver_to 'devs@company.name'
    end

    it 'has the correct subject' do
      is_expected.to have_subject /Deleted tag v1\.0/
    end
  end

  describe 'email on push with multiple commits' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, sample_image_commit.id, sample_commit.id) }
    let(:commits) { Commit.decorate(compare.commits, nil) }
    let(:diff_path) { namespace_project_compare_path(project.namespace, project, from: Commit.new(compare.base, project), to: Commit.new(compare.head, project)) }
    let(:send_from_committer_email) { false }

    subject { Notify.repository_push_email(project.id, 'devs@company.name', author_id: user.id, ref: 'refs/heads/master', action: :push, compare: compare, reverse_compare: false, send_from_committer_email: send_from_committer_email) }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'is sent to recipient' do
      is_expected.to deliver_to 'devs@company.name'
    end

    it 'has the correct subject' do
      is_expected.to have_subject /\[#{project.path_with_namespace}\]\[master\] #{commits.length} commits:/
    end

    it 'includes commits list' do
      is_expected.to have_body_text /Change some files/
    end

    it 'includes diffs' do
      is_expected.to have_body_text /def archive_formats_regex/
    end

    it 'contains a link to the diff' do
      is_expected.to have_body_text /#{diff_path}/
    end

    it 'doesn not contain the misleading footer' do
      is_expected.not_to have_body_text /you are a member of/
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
          sender = subject.header[:from].addrs[0]
          expect(sender.address).to eq(user.email)
        end

        it "is set to reply to the committer email" do
          sender = subject.header[:reply_to].addrs[0]
          expect(sender.address).to eq(user.email)
        end
      end

      context "when the committer email domain is not completely within the GitLab domain" do

        before do
          user.update_attribute(:email, "user@something.company.com")
          user.confirm
        end

        it "is sent from the default email" do
          sender = subject.header[:from].addrs[0]
          expect(sender.address).to eq(gitlab_sender)
        end

        it "is set to reply to the default email" do
          sender = subject.header[:reply_to].addrs[0]
          expect(sender.address).to eq(gitlab_sender_reply_to)
        end
      end

      context "when the committer email domain is outside the GitLab domain" do

        before do
          user.update_attribute(:email, "user@mpany.com")
          user.confirm
        end

        it "is sent from the default email" do
          sender = subject.header[:from].addrs[0]
          expect(sender.address).to eq(gitlab_sender)
        end

        it "is set to reply to the default email" do
          sender = subject.header[:reply_to].addrs[0]
          expect(sender.address).to eq(gitlab_sender_reply_to)
        end
      end
    end
  end

  describe 'email on push with a single commit' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, sample_commit.parent_id, sample_commit.id) }
    let(:commits) { Commit.decorate(compare.commits, nil) }
    let(:diff_path) { namespace_project_commit_path(project.namespace, project, commits.first) }

    subject { Notify.repository_push_email(project.id, 'devs@company.name', author_id: user.id, ref: 'refs/heads/master', action: :push, compare: compare) }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'is sent to recipient' do
      is_expected.to deliver_to 'devs@company.name'
    end

    it 'has the correct subject' do
      is_expected.to have_subject /#{commits.first.title}/
    end

    it 'includes commits list' do
      is_expected.to have_body_text /Change some files/
    end

    it 'includes diffs' do
      is_expected.to have_body_text /def archive_formats_regex/
    end

    it 'contains a link to the diff' do
      is_expected.to have_body_text /#{diff_path}/
    end
  end
end
