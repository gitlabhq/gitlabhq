require 'spec_helper'

describe Gitlab::Diff::ParallelDiff, lib: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diffs) { commit.diffs }
  let(:diff) { diffs.first }
  let(:diff_refs) { [commit.parent, commit] }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs) }
  subject { described_class.new(diff_file) }

  let(:parallel_diff_result_array) { YAML.load_file("#{Rails.root}/spec/fixtures/parallel_diff_result.yml") }

  describe '#parallelize' do
    it 'should return an array of arrays containing the parsed diff' do
      expect(subject.parallelize).to match_array(parallel_diff_result_array)
    end
  end
end
