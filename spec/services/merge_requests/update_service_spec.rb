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
    context 'valid params' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close'
        }
      end

      let(:service) { MergeRequests::UpdateService.new(project, user, opts) }

      before do
        service.stub(:execute_hooks)

        @merge_request = service.execute(merge_request)
        @merge_request.reload
      end

      it { @merge_request.should be_valid }
      it { @merge_request.title.should == 'New title' }
      it { @merge_request.assignee.should == user2 }
      it { @merge_request.should be_closed }

      it 'should execute hooks with update action' do
        expect(service).to have_received(:execute_hooks).
                               with(@merge_request, 'update')
      end

      it 'should send email to user2 about assign of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        email.to.first.should == user2.email
        email.subject.should include(merge_request.title)
      end

      it 'should create system note about merge_request reassign' do
        note = @merge_request.notes.reload.last
        note.note.should include "Reassigned to \@#{user2.username}"
      end
    end
  end
end
