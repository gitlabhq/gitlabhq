require 'spec_helper'

describe MergeRequests::UpdateService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }

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

        @merge_request = MergeRequests::UpdateService.new(project, user, opts).execute(merge_request)
      end

      it { @merge_request.should be_valid }
      it { @merge_request.title.should == 'New title' }
      it { @merge_request.assignee.should == user2 }
      it { @merge_request.should be_closed }

      it 'should send email to user2 about assign of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        email.cc.first.should == user2.email
        email.subject.should include(merge_request.title)
      end

      it 'should create system note about merge_request reassign' do
        note = @merge_request.notes.last
        note.note.should include "Reassigned to \@#{user2.username}"
      end
    end
  end
end
