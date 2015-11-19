require 'spec_helper'

describe MergeRequests::UpdateService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple, title: 'Old title', assignee_id: user3.id) }
  let(:project) { merge_request.project }
  let(:label) { create(:label) }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe 'execute' do
    context 'valid params' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close',
          label_ids: [label.id],
          target_branch: 'target'
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
      it { expect(@merge_request.target_branch).to eq('target') }

      it 'should execute hooks with update action' do
        expect(service).to have_received(:execute_hooks).
                               with(@merge_request, 'update')
      end

      it 'should send email to user2 about assign of new merge request and email to user3 about merge request unassignment' do
        deliveries = ActionMailer::Base.deliveries
        email = deliveries.last
        recipients = deliveries.last(2).map(&:to).flatten
        expect(recipients).to include(user2.email, user3.email)
        expect(email.subject).to include(merge_request.title)
      end

      def find_note(starting_with)
        @merge_request.notes.find do |note|
          note && note.note.start_with?(starting_with)
        end
      end

      it 'should create system note about merge_request reassign' do
        note = find_note('Reassigned to')

        expect(note).not_to be_nil
        expect(note.note).to include "Reassigned to \@#{user2.username}"
      end

      it 'should create system note about merge_request label edit' do
        note = find_note('Added ~')

        expect(note).not_to be_nil
        expect(note.note).to include "Added ~#{label.id} label"
      end

      it 'creates system note about title change' do
        note = find_note('Title changed')

        expect(note).not_to be_nil
        expect(note.note).to eq 'Title changed from **Old title** to **New title**'
      end

      it 'creates system note about branch change' do
        note = find_note('Target')

        expect(note).not_to be_nil
        expect(note.note).to eq 'Target branch changed from `master` to `target`'
      end
    end
  end
end
