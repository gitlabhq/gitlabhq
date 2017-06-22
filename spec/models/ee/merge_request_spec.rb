require 'spec_helper'

describe MergeRequest, models: true do
  subject { create(:merge_request) }

  describe '#rebase_in_progress?' do
    it 'returns true when there is a current rebase directory' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(subject.rebase_in_progress?).to be_truthy
    end

    it 'returns false when there is no rebase directory' do
      allow(File).to receive(:exist?).with(subject.rebase_dir_path).and_return(false)

      expect(subject.rebase_in_progress?).to be_falsey
    end

    it 'returns false when the rebase directory has expired' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(20.minutes.ago)

      expect(subject.rebase_in_progress?).to be_falsey
    end

    it 'returns false when the source project has been removed' do
      allow(subject).to receive(:source_project).and_return(nil)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(File).not_to have_received(:exist?)
      expect(subject.rebase_in_progress?).to be_falsey
    end
  end

  describe '#squash_in_progress?' do
    it 'returns true when there is a current squash directory' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(subject.squash_in_progress?).to be_truthy
    end

    it 'returns false when there is no squash directory' do
      allow(File).to receive(:exist?).with(subject.squash_dir_path).and_return(false)

      expect(subject.squash_in_progress?).to be_falsey
    end

    it 'returns false when the squash directory has expired' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(20.minutes.ago)

      expect(subject.squash_in_progress?).to be_falsey
    end

    it 'returns false when the source project has been removed' do
      allow(subject).to receive(:source_project).and_return(nil)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(File).not_to have_received(:exist?)
      expect(subject.squash_in_progress?).to be_falsey
    end
  end
end
