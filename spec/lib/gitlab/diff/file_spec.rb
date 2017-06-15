require 'spec_helper'

describe Gitlab::Diff::File, lib: true do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { described_class.new(diff, diff_refs: commit.diff_refs, repository: project.repository) }

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

  describe '#old_content_commit' do
    it 'returns base commit' do
      old_content_commit = diff_file.old_content_commit

      expect(old_content_commit.id).to eq('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
    end
  end

  describe '#old_blob' do
    it 'returns blob of commit of base commit' do
      old_data = diff_file.old_blob.data

      expect(old_data).to include('raise "System commands must be given as an array of strings"')
    end
  end

  describe '#new_blob' do
    it 'returns blob of new commit' do
      data = diff_file.new_blob.data

      expect(data).to include('raise RuntimeError, "System commands must be given as an array of strings"')
    end
  end

  describe '#diffable?' do
    let(:commit) { project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863') }
    let(:diffs) { commit.diffs }

    before do
      info_dir_path = File.join(project.repository.path_to_repo, 'info')

      FileUtils.mkdir(info_dir_path) unless File.exist?(info_dir_path)
      File.write(File.join(info_dir_path, 'attributes'), "*.md -diff\n")
    end

    it "returns true for files that do not have attributes" do
      diff_file = diffs.diff_file_with_new_path('LICENSE')
      expect(diff_file.diffable?).to be_truthy
    end

    it "returns false for files that have been marked as not being diffable in attributes" do
      diff_file = diffs.diff_file_with_new_path('README.md')
      expect(diff_file.diffable?).to be_falsey
    end
  end
end
