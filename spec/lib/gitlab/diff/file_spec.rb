require 'spec_helper'

describe Gitlab::Diff::File, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, [commit.parent, commit]) }

  describe :diff_lines do
    let(:diff_lines) { diff_file.diff_lines }

    it { expect(diff_lines.size).to eq(30) }
    it { expect(diff_lines.first).to be_kind_of(Gitlab::Diff::Line) }
  end

  describe :mode_changed? do
    it { expect(diff_file.mode_changed?).to be_falsey }
  end
end
