require 'spec_helper'

describe MergeRequests::CloseService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) { create(:merge_request, assignee: user2) }
  let(:project) { merge_request.project }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe :execute do
    context 'valid params' do
      let(:service) { MergeRequests::CloseService.new(project, user, {}) }

      before do
        allow(service).to receive(:execute_hooks)

        @merge_request = service.execute(merge_request)
      end

      it { expect(@merge_request).to be_valid }
      it { expect(@merge_request).to be_closed }

      it 'should execute hooks with close action' do
        expect(service).to have_received(:execute_hooks).
                               with(@merge_request, 'close')
      end

      it 'should send email to user2 about assign of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'should create system note about merge_request reassign' do
        note = @merge_request.notes.last
        expect(note.note).to include 'Status changed to closed'
      end
    end
  end
end
