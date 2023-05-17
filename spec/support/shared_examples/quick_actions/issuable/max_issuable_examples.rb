# frozen_string_literal: true

RSpec.shared_examples 'does not exceed the issuable size limit' do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  before do
    project.add_maintainer(user)
    project.add_maintainer(user1)
    project.add_maintainer(user2)
    project.add_maintainer(user3)
  end

  context "when the number of users of issuable does exceed the limit" do
    before do
      stub_const("Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS", 2)
    end

    it 'will not add more than the allowed number of users' do
      allow_next_instance_of(update_service) do |service|
        expect(service).not_to receive(:execute)
      end

      note = described_class.new(project, user, opts.merge(
        note: note_text,
        noteable_type: noteable_type,
        noteable_id: issuable.id,
        confidential: false
      )).execute

      expect(note.errors[:validation]).to match_array([validation_message])
    end
  end

  context "when the number of users does not exceed the limit" do
    before do
      stub_const("Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS", 6)
    end

    it 'calls execute and does not return an error' do
      allow_next_instance_of(update_service) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      note = described_class.new(project, user, opts.merge(
        note: note_text,
        noteable_type: noteable_type,
        noteable_id: issuable.id,
        confidential: false
      )).execute

      expect(note.errors[:validation]).to be_empty
    end
  end
end
