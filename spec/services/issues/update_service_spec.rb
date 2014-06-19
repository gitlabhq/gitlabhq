require 'spec_helper'

describe Issues::UpdateService do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:issue) { create(:issue) }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe :execute do
    context "valid params" do
      before do
        opts = {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close'
        }

        @issue = Issues::UpdateService.new(project, user, opts).execute(issue)
      end

      it { @issue.should be_valid }
      it { @issue.title.should == 'New title' }
      it { @issue.assignee.should == user2 }
      it { @issue.should be_closed }

      it 'should send email to user2 about assign of new issue' do
        email = ActionMailer::Base.deliveries.last
        email.to.first.should == user2.email
        email.subject.should include(issue.title)
      end

      it 'should create system note about issue reassign' do
        note = @issue.notes.last
        note.note.should include "Reassigned to \@#{user2.username}"
      end
    end
  end
end
