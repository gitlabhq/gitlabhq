require 'spec_helper'

describe Gitlab::Diff::File do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.repository.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff) }

  describe :diff_lines do
    let(:diff_lines) { diff_file.diff_lines }

    it { diff_lines.size.should == 30 }
    it { diff_lines.first.should be_kind_of(Gitlab::Diff::Line) }
  end

  describe :mode_changed? do
    it { diff_file.mode_changed?.should be_false }
  end
end
