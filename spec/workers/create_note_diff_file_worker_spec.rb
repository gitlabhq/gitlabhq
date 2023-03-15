# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateNoteDiffFileWorker, feature_category: :code_review_workflow do
  describe '#perform' do
    let(:diff_note) { create(:diff_note_on_merge_request) }

    it 'creates diff file' do
      diff_note.note_diff_file.destroy!

      expect_any_instance_of(DiffNote).to receive(:create_diff_file)
        .and_call_original

      described_class.new.perform(diff_note.id)
    end

    context "when the supplied diff_note_id doesn't belong to an existing DiffNote" do
      it "returns nil without raising an error" do
        expect_any_instance_of(DiffNote).not_to receive(:create_diff_file)
        .and_call_original

        described_class.new.perform(non_existing_record_id)
      end
    end

    context "when called with a missing diff_note id" do
      it "returns nil without creating diff file" do
        expect_any_instance_of(DiffNote).not_to receive(:create_diff_file)
        .and_call_original

        described_class.new.perform(nil)
      end
    end
  end
end
