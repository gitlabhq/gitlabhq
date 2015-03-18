require 'spec_helper'

describe MergeRequests::UpdateService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }
  let(:label) { create(:label) }

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
          state_event: 'close',
          label_ids: [label.id]
        }
      end

      let(:service) { MergeRequests::UpdateService.new(project, user, opts) }

      before do
        allow(service).to receive(:execute_hooks)

        @merge_request = service.execute(merge_request)
        @merge_request.reload
      end

      it { expect(@merge_request).to be_valid }
      it { expect(@merge_request.title).to eq('New title') }
      it { expect(@merge_request.assignee).to eq(user2) }
      it { expect(@merge_request).to be_closed }
      it { expect(@merge_request.labels.count).to eq(1) }
      it { expect(@merge_request.labels.first.title).to eq('Bug') }

      it 'should execute hooks with update action' do
        expect(service).to have_received(:execute_hooks).
                               with(@merge_request, 'update')
      end

      it 'should send email to user2 about assign of new merge_request' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'should create system note about merge_request reassign' do
        note = @merge_request.notes.last
        expect(note.note).to include "Reassigned to \@#{user2.username}"
      end

      it 'should create system note about merge_request label edit' do
        note = @merge_request.notes[1]
        expect(note.note).to include "Added ~#{label.id} label"
      end
    end
  end
end
