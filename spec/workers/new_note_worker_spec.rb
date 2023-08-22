# frozen_string_literal: true

require "spec_helper"

RSpec.describe NewNoteWorker, feature_category: :team_planning do
  context 'when Note found' do
    let(:note) { create(:note) }

    it "calls NotificationService#new_note" do
      expect_next_instance_of(NotificationService) do |service|
        expect(service).to receive(:new_note).with(note)
      end

      described_class.new.perform(note.id)
    end

    it "calls Notes::PostProcessService#execute" do
      expect_next_instance_of(Notes::PostProcessService) do |service|
        expect(service).to receive(:execute)
      end

      described_class.new.perform(note.id)
    end
  end

  context 'when Note not found' do
    let(:unexistent_note_id) { non_existing_record_id }

    it 'logs NewNoteWorker process skipping' do
      expect(Gitlab::AppLogger).to receive(:error)
        .with("NewNoteWorker: couldn't find note with ID=#{unexistent_note_id}, skipping job")

      described_class.new.perform(unexistent_note_id)
    end

    it 'does not raise errors' do
      expect { described_class.new.perform(unexistent_note_id) }.not_to raise_error
    end

    it "does not call NotificationService" do
      expect(NotificationService).not_to receive(:new)

      described_class.new.perform(unexistent_note_id)
    end

    it "does not call Notes::PostProcessService" do
      expect(Notes::PostProcessService).not_to receive(:new)

      described_class.new.perform(unexistent_note_id)
    end
  end

  context 'when note does not require notification' do
    let(:note) { create(:note) }

    before do
      allow_next_found_instance_of(Note) do |note|
        allow(note).to receive(:skip_notification?).and_return(true)
      end
    end

    it 'does not create a new note notification' do
      expect_any_instance_of(NotificationService).not_to receive(:new_note)

      subject.perform(note.id)
    end
  end

  context 'when Note author has been blocked' do
    let_it_be(:note) { create(:note, author: create(:user, :blocked)) }

    it "does not call NotificationService" do
      expect(NotificationService).not_to receive(:new)

      described_class.new.perform(note.id)
    end
  end

  context 'when Note author has been deleted' do
    let_it_be(:note) { create(:note, author: Users::Internal.ghost) }

    it "does not call NotificationService" do
      expect(NotificationService).not_to receive(:new)

      described_class.new.perform(note.id)
    end
  end
end
