# frozen_string_literal: true

require "spec_helper"

describe NewNoteWorker do
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
    let(:unexistent_note_id) { 999 }

    it 'logs NewNoteWorker process skipping' do
      expect(Rails.logger).to receive(:error)
        .with("NewNoteWorker: couldn't find note with ID=999, skipping job")

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
end
