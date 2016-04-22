require 'spec_helper'

describe MergeRequests::UpdateService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label) }

  let(:merge_request) do
    create(:merge_request, :simple, title: 'Old title',
                                    assignee_id: user3.id,
                                    source_project: project)
  end

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe 'execute' do
    def find_note(starting_with)
      @merge_request.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    def update_merge_request(opts)
      @merge_request = MergeRequests::UpdateService.new(project, user, opts).execute(merge_request)
      @merge_request.reload
    end

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

        perform_enqueued_jobs do
          @merge_request = service.execute(merge_request)
          @merge_request.reload
        end
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

    context 'when MergeRequest has tasks' do
      before { update_merge_request({ description: "- [ ] Task 1\n- [ ] Task 2" }) }

      it { expect(@merge_request.tasks?).to eq(true) }

      context 'when tasks are marked as completed' do
        before { update_merge_request({ description: "- [x] Task 1\n- [X] Task 2" }) }

        it 'creates system note about task status change' do
          note1 = find_note('Marked the task **Task 1** as completed')
          note2 = find_note('Marked the task **Task 2** as completed')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil
        end
      end

      context 'when tasks are marked as incomplete' do
        before do
          update_merge_request({ description: "- [x] Task 1\n- [X] Task 2" })
          update_merge_request({ description: "- [ ] Task 1\n- [ ] Task 2" })
        end

        it 'creates system note about task status change' do
          note1 = find_note('Marked the task **Task 1** as incomplete')
          note2 = find_note('Marked the task **Task 2** as incomplete')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil
        end
      end
    end

  end
end
