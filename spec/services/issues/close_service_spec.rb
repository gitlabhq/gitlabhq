require 'spec_helper'

describe Issues::CloseService do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:issue) { create(:issue, assignee: user2) }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe :execute do
    context "valid params" do
      before do
        @issue = Issues::CloseService.new(project, user, {}).execute(issue)
      end

      it { @issue.should be_valid }
      it { @issue.should be_closed }

      it 'should send email to user2 about assign of new issue' do
        email = ActionMailer::Base.deliveries.last
        email.to.first.should == user2.email
        email.subject.should include(issue.title)
      end

      it 'should create system note about issue reassign' do
        note = @issue.notes.last
        note.note.should include "Status changed to closed"
      end
    end
  end
end
