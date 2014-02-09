require 'spec_helper'

describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  let(:recipient) { create(:user, email: 'recipient@example.com') }
  let(:project) { create(:project) }

  shared_examples 'a multiple recipients email' do
    it 'is sent to the given recipient' do
      should deliver_to recipient.email
    end
  end

  describe 'for new users, the email' do
    let(:example_site_path) { root_path }
    let(:new_user) { create(:user, email: 'newguy@example.com', created_by_id: 1) }

    subject { Notify.new_user_email(new_user.id, new_user.password) }

    it 'is sent to the new user' do
      should deliver_to new_user.email
    end

    it 'has the correct subject' do
      should have_subject /^gitlab \| Account was created for you$/i
    end

    it 'contains the new user\'s login name' do
      should have_body_text /#{new_user.email}/
    end

    it 'contains the new user\'s password' do
      should have_body_text /password/
    end

    it 'includes a link to the site' do
      should have_body_text /#{example_site_path}/
    end
  end


  describe 'for users that signed up, the email' do
    let(:example_site_path) { root_path }
    let(:new_user) { create(:user, email: 'newguy@example.com', password: "securePassword") }

    subject { Notify.new_user_email(new_user.id, new_user.password) }

    it 'is sent to the new user' do
      should deliver_to new_user.email
    end

    it 'has the correct subject' do
      should have_subject /^gitlab \| Account was created for you$/i
    end

    it 'contains the new user\'s login name' do
      should have_body_text /#{new_user.email}/
    end

    it 'should not contain the new user\'s password' do
      should_not have_body_text /password/
    end

    it 'includes a link to the site' do
      should have_body_text /#{example_site_path}/
    end
  end

  describe 'user added ssh key' do
    let(:key) { create(:personal_key) }

    subject { Notify.new_ssh_key_email(key.id) }

    it 'is sent to the new user' do
      should deliver_to key.user.email
    end

    it 'has the correct subject' do
      should have_subject /^gitlab \| SSH key was added to your account$/i
    end

    it 'contains the new ssh key title' do
      should have_body_text /#{key.title}/
    end

    it 'includes a link to ssh keys page' do
      should have_body_text /#{profile_keys_path}/
    end
  end

  describe 'user added email' do
    let(:email) { create(:email) }

    subject { Notify.new_email_email(email.id) }

    it 'is sent to the new user' do
      should deliver_to email.user.email
    end

    it 'has the correct subject' do
      should have_subject /^gitlab \| Email was added to your account$/i
    end

    it 'contains the new email address' do
      should have_body_text /#{email.email}/
    end

    it 'includes a link to emails page' do
      should have_body_text /#{profile_emails_path}/
    end
  end

  context 'for a project' do
    describe 'items that are assignable, the email' do
      let(:assignee) { create(:user, email: 'assignee@example.com') }
      let(:previous_assignee) { create(:user, name: 'Previous Assignee') }

      shared_examples 'an assignee email' do
        it 'is sent to the assignee' do
          should deliver_to assignee.email
        end
      end

      context 'for issues' do
        let(:issue) { create(:issue, assignee: assignee, project: project ) }

        describe 'that are new' do
          subject { Notify.new_issue_email(issue.assignee_id, issue.id) }

          it_behaves_like 'an assignee email'

          it 'has the correct subject' do
            should have_subject /#{project.name} \| New issue ##{issue.iid} \| #{issue.title}/
          end

          it 'contains a link to the new issue' do
            should have_body_text /#{project_issue_path project, issue}/
          end
        end

        describe 'that have been reassigned' do
          before(:each) { issue.stub(:assignee_id_was).and_return(previous_assignee.id) }

          subject { Notify.reassigned_issue_email(recipient.id, issue.id, previous_assignee.id) }

          it_behaves_like 'a multiple recipients email'

          it 'has the correct subject' do
            should have_subject /Changed issue ##{issue.iid} \| #{issue.title}/
          end

          it 'contains the name of the previous assignee' do
            should have_body_text /#{previous_assignee.name}/
          end

          it 'contains the name of the new assignee' do
            should have_body_text /#{assignee.name}/
          end

          it 'contains a link to the issue' do
            should have_body_text /#{project_issue_path project, issue}/
          end
        end

        describe 'status changed' do
          let(:current_user) { create(:user, email: "current@email.com") }
          let(:status) { 'closed' }
          subject { Notify.issue_status_changed_email(recipient.id, issue.id, status, current_user) }

          it 'has the correct subject' do
            should have_subject /Changed issue ##{issue.iid} \| #{issue.title}/i
          end

          it 'contains the new status' do
            should have_body_text /#{status}/i
          end

          it 'contains the user name' do
            should have_body_text /#{current_user.name}/i
          end

          it 'contains a link to the issue' do
            should have_body_text /#{project_issue_path project, issue}/
          end
        end

      end

      context 'for merge requests' do
        let(:merge_request) { create(:merge_request, assignee: assignee, source_project: project, target_project: project) }

        describe 'that are new' do
          subject { Notify.new_merge_request_email(merge_request.assignee_id, merge_request.id) }

          it_behaves_like 'an assignee email'

          it 'has the correct subject' do
            should have_subject /New merge request ##{merge_request.iid}/
          end

          it 'contains a link to the new merge request' do
            should have_body_text /#{project_merge_request_path(project, merge_request)}/
          end

          it 'contains the source branch for the merge request' do
            should have_body_text /#{merge_request.source_branch}/
          end

          it 'contains the target branch for the merge request' do
            should have_body_text /#{merge_request.target_branch}/
          end
        end

        describe 'that are reassigned' do
          before(:each) { merge_request.stub(:assignee_id_was).and_return(previous_assignee.id) }

          subject { Notify.reassigned_merge_request_email(recipient.id, merge_request.id, previous_assignee.id) }

          it_behaves_like 'a multiple recipients email'

          it 'has the correct subject' do
            should have_subject /Changed merge request ##{merge_request.iid}/
          end

          it 'contains the name of the previous assignee' do
            should have_body_text /#{previous_assignee.name}/
          end

          it 'contains the name of the new assignee' do
            should have_body_text /#{assignee.name}/
          end

          it 'contains a link to the merge request' do
            should have_body_text /#{project_merge_request_path project, merge_request}/
          end

        end
      end
    end

    describe 'project was moved' do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      subject { Notify.project_was_moved_email(project.id, user.id) }

      it 'has the correct subject' do
        should have_subject /Project was moved/
      end

      it 'contains name of project' do
        should have_body_text /#{project.name_with_namespace}/
      end

      it 'contains new user role' do
        should have_body_text /#{project.ssh_url_to_repo}/
      end
    end

    describe 'project access changed' do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      let(:users_project) { create(:users_project,
                                   project: project,
                                   user: user) }
      subject { Notify.project_access_granted_email(users_project.id) }
      it 'has the correct subject' do
        should have_subject /Access to project was granted/
      end
      it 'contains name of project' do
        should have_body_text /#{project.name}/
      end
      it 'contains new user role' do
        should have_body_text /#{users_project.human_access}/
      end
    end

    context 'items that are noteable, the email for a note' do
      let(:note_author) { create(:user, name: 'author_name') }
      let(:note) { create(:note, project: project, author: note_author) }

      before :each do
        Note.stub(:find).with(note.id).and_return(note)
      end

      shared_examples 'a note email' do
        it 'is sent to the given recipient' do
          should deliver_to recipient.email
        end

        it 'contains the name of the note\'s author' do
          should have_body_text /#{note_author.name}/
        end

        it 'contains the message from the note' do
          should have_body_text /#{note.note}/
        end
      end

      describe 'on a project wall' do
        let(:note_on_the_wall_path) { project_wall_path(project, anchor: "note_#{note.id}") }

        subject { Notify.note_wall_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it 'has the correct subject' do
          should have_subject /#{project.name}/
        end

        it 'contains a link to the wall note' do
          should have_body_text /#{note_on_the_wall_path}/
        end
      end

      describe 'on a commit' do
        let(:commit) { project.repository.commit }

        before(:each) { note.stub(:noteable).and_return(commit) }

        subject { Notify.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it 'has the correct subject' do
          should have_subject /Note for commit #{commit.short_id}/
        end

        it 'contains a link to the commit' do
          should have_body_text commit.short_id
        end
      end

      describe 'on a merge request' do
        let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
        let(:note_on_merge_request_path) { project_merge_request_path(project, merge_request, anchor: "note_#{note.id}") }
        before(:each) { note.stub(:noteable).and_return(merge_request) }

        subject { Notify.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it 'has the correct subject' do
          should have_subject /Note for merge request ##{merge_request.iid}/
        end

        it 'contains a link to the merge request note' do
          should have_body_text /#{note_on_merge_request_path}/
        end
      end

      describe 'on an issue' do
        let(:issue) { create(:issue, project: project) }
        let(:note_on_issue_path) { project_issue_path(project, issue, anchor: "note_#{note.id}") }
        before(:each) { note.stub(:noteable).and_return(issue) }

        subject { Notify.note_issue_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it 'has the correct subject' do
          should have_subject /Note for issue ##{issue.iid}/
        end

        it 'contains a link to the issue note' do
          should have_body_text /#{note_on_issue_path}/
        end
      end
    end
  end

  describe 'group access changed' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let(:membership) { create(:users_group, group: group, user: user) }

    subject { Notify.group_access_granted_email(membership.id) }

    it 'has the correct subject' do
      should have_subject /Access to group was granted/
    end

    it 'contains name of project' do
      should have_body_text /#{group.name}/
    end

    it 'contains new user role' do
      should have_body_text /#{membership.human_access}/
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

    it 'is sent to the new user' do
      should deliver_to 'new-email@mail.com'
    end

    it 'has the correct subject' do
      should have_subject "Confirmation instructions"
    end

    it 'includes a link to the site' do
      should have_body_text /#{example_site_path}/
    end
  end

  describe 'email on push' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, 'cd5c4bac', 'b1e6a9db') }

    subject { Notify.repository_push_email(project.id, 'devs@company.name', user.id, 'master', compare) }

    it 'is sent to recipient' do
      should deliver_to 'devs@company.name'
    end

    it 'has the correct subject' do
      should have_subject /New push to repository/
    end

    it 'includes commits list' do
      should have_body_text /tree css fixes/
    end

    it 'includes diffs' do
      should have_body_text /Checkout wiki pages for installation information/
    end
  end
end
