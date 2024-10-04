# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::ParallelDiff do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diffs) { commit.raw_diffs }
  let(:diff) { diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: commit.diff_refs, repository: repository) }

  subject { described_class.new(diff_file) }

  describe '#parallelize' do
    it 'returns an array of arrays containing the parsed diff' do
      diff_lines = diff_file.highlighted_diff_lines
      expected = [
        # Unchanged lines
        { left: diff_lines[0], right: diff_lines[0] },
        { left: diff_lines[1], right: diff_lines[1] },
        { left: diff_lines[2], right: diff_lines[2] },
        { left: diff_lines[3], right: diff_lines[3] },
        { left: diff_lines[4], right: diff_lines[5] },
        { left: diff_lines[6], right: diff_lines[6] },
        { left: diff_lines[7], right: diff_lines[7] },
        { left: diff_lines[8], right: diff_lines[8] },

        # Changed lines
        { left: diff_lines[9], right: diff_lines[11] },
        { left: diff_lines[10], right: diff_lines[12] },

        # Added lines
        { left: nil, right: diff_lines[13] },
        { left: nil, right: diff_lines[14] },
        { left: nil, right: diff_lines[15] },
        { left: nil, right: diff_lines[16] },
        { left: nil, right: diff_lines[17] },
        { left: nil, right: diff_lines[18] },

        # Unchanged lines
        { left: diff_lines[19], right: diff_lines[19] },
        { left: diff_lines[20], right: diff_lines[20] },
        { left: diff_lines[21], right: diff_lines[21] },
        { left: diff_lines[22], right: diff_lines[22] },
        { left: diff_lines[23], right: diff_lines[23] },
        { left: diff_lines[24], right: diff_lines[24] },
        { left: diff_lines[25], right: diff_lines[25] },

        # Added line
        { left: nil, right: diff_lines[26] },

        # Unchanged lines
        { left: diff_lines[27], right: diff_lines[27] },
        { left: diff_lines[28], right: diff_lines[28] },
        { left: diff_lines[29], right: diff_lines[29] }
      ]

      expect(subject.parallelize).to eq(expected)
    end

    it 'works as a static method' do
      diff_lines = [Gitlab::Diff::Line.new("", 'match', nil, 1, 1)]
      expect(described_class.parallelize(diff_lines)).to eq([
        {
          left: diff_lines[0], right: diff_lines[0]
        }
      ])
    end
  end
end
