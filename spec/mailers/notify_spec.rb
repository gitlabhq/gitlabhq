require 'spec_helper'

describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  before :all do
    default_url_options[:host] = EMAIL_OPTS['host']
  end

  let(:recipient) { Factory.create(:user, :email => 'recipient@example.com') }
  let(:project) { Factory.create(:project) }

  shared_examples 'a multiple recipients email' do
    it 'is sent to the given recipient' do
      should deliver_to recipient.email
    end
  end

  describe 'for new users, the email' do
    let(:example_site_url) { root_url }
    let(:new_user) { Factory.create(:user, :email => 'newguy@example.com') }

    subject { Notify.new_user_email(new_user.id, new_user.password) }

    it 'is sent to the new user' do
      should deliver_to new_user.email
    end

    it 'has the correct subject' do
      should have_subject /Account was created for you/
    end

    it 'contains the new user\'s login name' do
      should have_body_text /#{new_user.email}/
    end

    it 'contains the new user\'s password' do
      should have_body_text /#{new_user.password}/
    end

    it 'includes a link to the site' do
      should have_body_text /#{example_site_url}/
    end
  end

  context 'for a project' do
    describe 'items that are assignable, the email' do
      let(:assignee) { Factory.create(:user, :email => 'assignee@example.com') }
      let(:previous_assignee) { Factory.create(:user, :name => 'Previous Assignee') }

      shared_examples 'an assignee email' do
        it 'is sent to the assignee' do
          should deliver_to assignee.email
        end
      end

      context 'for issues' do
        let(:issue) { Factory.create(:issue, :assignee => assignee, :project => project ) }

        describe 'that are new' do
          subject { Notify.new_issue_email(issue.id) }

          it_behaves_like 'an assignee email'

          it 'has the correct subject' do
            should have_subject /New Issue was created/
          end

          it 'contains a link to the new issue' do
            should have_body_text /#{project_issue_url project, issue}/
          end
        end

        describe 'that have been reassigned' do
          before(:each) { issue.stub(:assignee_id_was).and_return(previous_assignee.id) }

          subject { Notify.reassigned_issue_email(recipient.id, issue.id, previous_assignee.id) }

          it_behaves_like 'a multiple recipients email'

          it 'has the correct subject' do
            should have_subject /changed issue/
          end

          it 'contains the name of the previous assignee' do
            should have_body_text /#{previous_assignee.name}/
          end

          it 'contains the name of the new assignee' do
            should have_body_text /#{assignee.name}/
          end

          it 'contains a link to the issue' do
            should have_body_text /#{project_issue_url project, issue}/
          end
        end
      end

      context 'for merge requests' do
        let(:merge_request) { Factory.create(:merge_request, :assignee => assignee, :project => project) }

        describe 'that are new' do
          subject { Notify.new_merge_request_email(merge_request.id) }

          it_behaves_like 'an assignee email'

          it 'has the correct subject' do
            should have_subject /new merge request/
          end

          it 'contains a link to the new merge request' do
            should have_body_text /#{project_merge_request_url(project, merge_request)}/
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
            should have_subject /merge request changed/
          end

          it 'contains the name of the previous assignee' do
            should have_body_text /#{previous_assignee.name}/
          end

          it 'contains the name of the new assignee' do
            should have_body_text /#{assignee.name}/
          end

          it 'contains a link to the merge request' do
            should have_body_text /#{project_merge_request_url project, merge_request}/
          end

        end
      end
    end

    context 'items that are noteable, the email for a note' do
      let(:note_author) { Factory.create(:user, :name => 'author_name') }
      let(:note) { Factory.create(:note, :project => project, :author => note_author) }

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
        let(:note_on_the_wall_url) { wall_project_url(project, :anchor => "note_#{note.id}") }

        subject { Notify.note_wall_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it 'has the correct subject' do
          should have_subject /#{project.name}/
        end

        it 'contains a link to the wall note' do
          should have_body_text /#{note_on_the_wall_url}/
        end
      end

      describe 'on a commit' do
        let(:commit) do
          mock(:commit).tap do |commit|
            commit.stub(:id).and_return('fauxsha1')
            commit.stub(:project).and_return(project)
          end
        end
        before(:each) { note.stub(:target).and_return(commit) }

        subject { Notify.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it 'has the correct subject' do
          should have_subject /note for commit/
        end

        it 'contains a link to the commit' do
          should have_body_text /fauxsha1/
        end
      end

      describe 'on a merge request' do
        let(:merge_request) { Factory.create(:merge_request, :project => project) }
        let(:note_on_merge_request_url) { project_merge_request_url(project, merge_request, :anchor => "note_#{note.id}") }
        before(:each) { note.stub(:noteable).and_return(merge_request) }

        subject { Notify.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it 'has the correct subject' do
          should have_subject /note for merge request/
        end

        it 'contains a link to the merge request note' do
          should have_body_text /#{note_on_merge_request_url}/
        end
      end

      describe 'on an issue' do
        let(:issue) { Factory.create(:issue, :project => project) }
        let(:note_on_issue_url) { project_issue_url(project, issue, :anchor => "note_#{note.id}") }
        before(:each) { note.stub(:noteable).and_return(issue) }

        subject { Notify.note_issue_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it 'has the correct subject' do
          should have_subject /note for issue #{issue.id}/
        end

        it 'contains a link to the issue note' do
          should have_body_text /#{note_on_issue_url}/
        end
      end
    end
  end
end
