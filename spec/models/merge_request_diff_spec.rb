require 'spec_helper'

describe MergeRequestDiff, models: true do
  describe '#diffs' do
    let(:mr) { create(:merge_request, :with_diffs) }
    let(:mr_diff) { mr.merge_request_diff }

    context 'when the :ignore_whitespace_change option is set' do
      it 'creates a new compare object instead of loading from the DB' do
        expect(mr_diff).not_to receive(:load_diffs)
        expect(Gitlab::Git::Compare).to receive(:new).and_call_original

        mr_diff.raw_diffs(ignore_whitespace_change: true)
      end
    end

    context 'when the raw diffs are empty' do
      before { mr_diff.update_attributes(st_diffs: '') }

      it 'returns an empty DiffCollection' do
        expect(mr_diff.raw_diffs).to be_a(Gitlab::Git::DiffCollection)
        expect(mr_diff.raw_diffs).to be_empty
      end
    end

    context 'when the raw diffs exist' do
      it 'returns the diffs' do
        expect(mr_diff.raw_diffs).to be_a(Gitlab::Git::DiffCollection)
        expect(mr_diff.raw_diffs).not_to be_empty
      end

      context 'when the :paths option is set' do
        let(:diffs) { mr_diff.raw_diffs(paths: ['files/ruby/popen.rb', 'files/ruby/popen.rb']) }

        it 'only returns diffs that match the (old path, new path) given' do
          expect(diffs.map(&:new_path)).to contain_exactly('files/ruby/popen.rb')
        end

        it 'uses the diffs from the DB' do
          expect(mr_diff).to receive(:load_diffs)

          diffs
        end
      end
    end
  end
end
