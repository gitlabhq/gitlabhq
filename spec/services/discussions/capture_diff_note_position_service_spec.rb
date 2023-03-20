# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Discussions::CaptureDiffNotePositionService, feature_category: :code_review_workflow do
  subject { described_class.new(note.noteable, paths) }

  context 'image note on diff' do
    let!(:note) { create(:image_diff_note_on_merge_request) }
    let(:paths) { ['files/images/any_image.png'] }

    it 'is note affected by the service' do
      expect(Gitlab::Diff::PositionTracer).not_to receive(:new)

      expect(subject.execute(note.discussion)).to eq(nil)
      expect(note.diff_note_positions).to be_empty
    end
  end

  context 'when empty paths are passed as a param' do
    let!(:note) { create(:diff_note_on_merge_request) }
    let(:paths) { [] }

    it 'does not calculate positons' do
      expect(Gitlab::Diff::PositionTracer).not_to receive(:new)

      expect(subject.execute(note.discussion)).to eq(nil)
      expect(note.diff_note_positions).to be_empty
    end
  end

  context 'when position tracer returned position' do
    let!(:note) { create(:diff_note_on_merge_request) }
    let(:paths) { ['files/any_file.txt'] }

    before do
      expect(note.noteable).to receive(:merge_ref_head).and_return(double.as_null_object)
      expect_next_instance_of(Gitlab::Diff::PositionTracer) do |tracer|
        expect(tracer).to receive(:trace).and_return({ position: position })
      end
    end

    context 'which is nil' do
      let(:position) { nil }

      it 'does not create diff note position' do
        expect(subject.execute(note.discussion)).to eq(nil)
        expect(note.diff_note_positions).to be_empty
      end
    end

    context 'which does not have a corresponding line' do
      let(:position) { double(line_code: nil) }

      it 'does not create diff note position' do
        expect(subject.execute(note.discussion)).to eq(nil)
        expect(note.diff_note_positions).to be_empty
      end
    end
  end
end
