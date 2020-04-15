# frozen_string_literal: true

require 'spec_helper'

describe Discussions::CaptureDiffNotePositionService do
  context 'image note on diff' do
    let!(:note) { create(:image_diff_note_on_merge_request) }

    subject { described_class.new(note.noteable, ['files/images/any_image.png']) }

    it 'is note affected by the service' do
      expect(Gitlab::Diff::PositionTracer).not_to receive(:new)

      expect(subject.execute(note.discussion)).to eq(nil)
      expect(note.diff_note_positions).to be_empty
    end
  end

  context 'when empty paths are passed as a param' do
    let!(:note) { create(:diff_note_on_merge_request) }

    subject { described_class.new(note.noteable, []) }

    it 'does not calculate positons' do
      expect(Gitlab::Diff::PositionTracer).not_to receive(:new)

      expect(subject.execute(note.discussion)).to eq(nil)
      expect(note.diff_note_positions).to be_empty
    end
  end
end
