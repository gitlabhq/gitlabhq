require 'spec_helper'

describe CreateNoteDiffFileWorker do
  describe '#perform' do
    let(:diff_note) { create(:diff_note_on_merge_request) }

    it 'creates diff file' do
      diff_note.note_diff_file.destroy!

      expect_any_instance_of(DiffNote).to receive(:create_diff_file)
        .and_call_original

      described_class.new.perform(diff_note.id)
    end
  end
end
