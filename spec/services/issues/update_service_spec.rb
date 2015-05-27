require 'spec_helper'

describe Issues::UpdateService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:issue) { create(:issue, title: 'Old title') }
  let(:label) { create(:label) }
  let(:project) { issue.project }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe 'execute' do
    context "valid params" do
      before do
        opts = {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close',
          label_ids: [label.id]
        }

        @issue = Issues::UpdateService.new(project, user, opts).execute(issue)
        @issue.reload
      end

      it { expect(@issue).to be_valid }
      it { expect(@issue.title).to eq('New title') }
      it { expect(@issue.assignee).to eq(user2) }
      it { expect(@issue).to be_closed }
      it { expect(@issue.labels.count).to eq(1) }
      it { expect(@issue.labels.first.title).to eq('Bug') }

      it 'should send email to user2 about assign of new issue' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(issue.title)
      end

      def find_note(starting_with)
        @issue.notes.find do |note|
          note && note.note.start_with?(starting_with)
        end
      end

      it 'should create system note about issue reassign' do
        note = find_note('Reassigned to')

        expect(note).not_to be_nil
        expect(note.note).to include "Reassigned to \@#{user2.username}"
      end

      it 'should create system note about issue label edit' do
        note = find_note('Added ~')

        expect(note).not_to be_nil
        expect(note.note).to include "Added ~#{label.id} label"
      end

      it 'creates system note about title change' do
        note = find_note('Title changed')

        expect(note).not_to be_nil
        expect(note.note).to eq 'Title changed from **Old title** to **New title**'
      end
    end
  end
end
