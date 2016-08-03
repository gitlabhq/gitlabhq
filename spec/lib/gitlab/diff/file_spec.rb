require 'spec_helper'

describe Gitlab::Diff::File, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: commit.diff_refs, repository: project.repository) }

  describe '#diff_lines' do
    let(:diff_lines) { diff_file.diff_lines }

    it { expect(diff_lines.size).to eq(30) }
    it { expect(diff_lines.first).to be_kind_of(Gitlab::Diff::Line) }
  end

  describe '#mode_changed?' do
    it { expect(diff_file.mode_changed?).to be_falsey }
  end

  describe '#too_large?' do
    it 'returns true for a file that is too large' do
      expect(diff).to receive(:too_large?).and_return(true)

      expect(diff_file.too_large?).to eq(true)
    end

    it 'returns false for a file that is small enough' do
      expect(diff).to receive(:too_large?).and_return(false)

      expect(diff_file.too_large?).to eq(false)
    end
  end

  describe '#collapsed?' do
    it 'returns true for a file that is quite big' do
      expect(diff).to receive(:collapsed?).and_return(true)

      expect(diff_file.collapsed?).to eq(true)
    end

    it 'returns false for a file that is small enough' do
      expect(diff).to receive(:collapsed?).and_return(false)

      expect(diff_file.collapsed?).to eq(false)
    end
  end
end
