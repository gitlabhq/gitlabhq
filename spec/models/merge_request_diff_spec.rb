require 'spec_helper'

describe MergeRequestDiff, models: true do
  describe 'initialize new object' do
    subject { build(:merge_request).merge_request_diffs.build }

    it { expect(subject).to be_valid }
    it { expect(subject.head_commit_sha).to eq('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    it { expect(subject.base_commit_sha).to eq('ae73cb07c9eeaf35924a10f713b364d32b2dd34f') }
    it { expect(subject.start_commit_sha).to eq('0b4bc9a49b562e85de7cc9e834518ea6828729b9') }
  end

  describe 'create new record' do
    subject { create(:merge_request).merge_request_diff }

    it { expect(subject).to be_valid }
    it { expect(subject).to be_persisted }
    it { expect(subject.commits.count).to eq(5) }
    it { expect(subject.diffs.count).to eq(8) }
  end

  describe '#diffs' do
    let(:mr) { create(:merge_request, :with_diffs) }
    let(:mr_diff) { mr.merge_request_diff }

    context 'when the :ignore_whitespace_change option is set' do
      it 'creates a new compare object instead of loading from the DB' do
        expect(mr_diff).not_to receive(:load_diffs)
        expect(Gitlab::Git::Compare).to receive(:new).and_call_original

        mr_diff.diffs(ignore_whitespace_change: true)
      end
    end

    context 'when the raw diffs are empty' do
      before { mr_diff.update_attributes(st_diffs: '') }

      it 'returns an empty DiffCollection' do
        expect(mr_diff.diffs).to be_a(Gitlab::Git::DiffCollection)
        expect(mr_diff.diffs).to be_empty
      end
    end

    context 'when the raw diffs exist' do
      it 'returns the diffs' do
        expect(mr_diff.diffs).to be_a(Gitlab::Git::DiffCollection)
        expect(mr_diff.diffs).not_to be_empty
      end

      context 'when the :paths option is set' do
        let(:diffs) { mr_diff.diffs(paths: ['files/ruby/popen.rb', 'files/ruby/popen.rb']) }

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
