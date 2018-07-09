require 'spec_helper'

describe Gitlab::BackgroundMigration::DeleteDiffFiles, :migration, schema: 20180626125654 do
  describe '#perform' do
    context 'when diff files can be deleted' do
      let(:merge_request) { create(:merge_request, :merged) }
      let(:merge_request_diff) do
        merge_request.create_merge_request_diff
        merge_request.merge_request_diffs.first
      end

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

      it 'rollsback if something goes wrong' do
        expect(MergeRequestDiffFile).to receive_message_chain(:where, :delete_all)
          .and_raise

        expect { described_class.new.perform(merge_request_diff.id) }
          .to raise_error

        merge_request_diff.reload

        expect(merge_request_diff.state).to eq('collected')
        expect(merge_request_diff.merge_request_diff_files.count).to eq(20)
      end
    end

    it 'deletes no merge request diff files when MR is not merged' do
      merge_request = create(:merge_request, :opened)
      merge_request.create_merge_request_diff
      merge_request_diff = merge_request.merge_request_diffs.first

      expect { described_class.new.perform(merge_request_diff.id) }
        .not_to change { merge_request_diff.merge_request_diff_files.count }
        .from(20)
    end

    it 'deletes no merge request diff files when diff is marked as "without_files"' do
      merge_request = create(:merge_request, :merged)
      merge_request.create_merge_request_diff
      merge_request_diff = merge_request.merge_request_diffs.first

      merge_request_diff.clean!

      expect { described_class.new.perform(merge_request_diff.id) }
        .not_to change { merge_request_diff.merge_request_diff_files.count }
        .from(20)
    end

    it 'deletes no merge request diff files when diff is the latest' do
      merge_request = create(:merge_request, :merged)
      merge_request_diff = merge_request.merge_request_diff

      expect { described_class.new.perform(merge_request_diff.id) }
        .not_to change { merge_request_diff.merge_request_diff_files.count }
        .from(20)
    end
  end
end
