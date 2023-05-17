# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeleteDiffFilesWorker, feature_category: :code_review_workflow do
  describe '#perform' do
    let(:merge_request) { create(:merge_request) }
    let(:merge_request_diff) { merge_request.merge_request_diff }

    it 'deletes all merge request diff files' do
      expect { described_class.new.perform(merge_request_diff.id) }
        .to change { merge_request_diff.merge_request_diff_files.count }
        .from(20).to(0)
    end

    it 'updates state to without_files' do
      expect { described_class.new.perform(merge_request_diff.id) }
        .to change { merge_request_diff.reload.state }
        .from('collected').to('without_files')
    end

    it 'resets the files_count of the diff' do
      expect { described_class.new.perform(merge_request_diff.id) }
        .to change { merge_request_diff.reload.files_count }
        .from(20).to(0)
    end

    it 'does nothing if diff was already marked as "without_files"' do
      merge_request_diff.clean!

      expect_any_instance_of(MergeRequestDiff).not_to receive(:clean!)

      described_class.new.perform(merge_request_diff.id)
    end

    it 'rollsback if something goes wrong' do
      error = RuntimeError.new('something went wrong')

      expect(MergeRequestDiffFile).to receive_message_chain(:where, :delete_all)
        .and_raise(error)

      expect { described_class.new.perform(merge_request_diff.id) }
        .to raise_error(error)

      merge_request_diff.reload

      expect(merge_request_diff.state).to eq('collected')
      expect(merge_request_diff.merge_request_diff_files.count).to eq(20)
    end
  end
end
