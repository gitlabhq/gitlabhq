require 'spec_helper'

describe Gitlab::Diff::LineMapper do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diffs) { commit.raw_diffs }
  let(:diff) { diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: commit.diff_refs, repository: repository) }
  subject { described_class.new(diff_file) }

  describe '#old_to_new' do
    context "with a diff file" do
      let(:mapping) do
        {
          1 => 1,
          2 => 2,
          3 => 3,
          4 => 4,
          5 => 5,
          6 => 6,
          7 => 7,
          8 => 8,
          9 => nil,
          # nil => 9,
          10 => 10,
          11 => 11,
          12 => 12,
          13 => nil,
          14 => nil,
          # nil => 15,
          # nil => 16,
          # nil => 17,
          # nil => 18,
          # nil => 19,
          # nil => 20,
          15 => 21,
          16 => 22,
          17 => 23,
          18 => 24,
          19 => 25,
          20 => 26,
          21 => 27,
          # nil => 28,
          22 => 29,
          23 => 30,
          24 => 31,
          25 => 32,
          26 => 33,
          27 => 34,
          28 => 35,
          29 => 36,
          30 => 37
        }
      end

      it 'returns the new line number for the old line number' do
        mapping.each do |old_line, new_line|
          expect(subject.old_to_new(old_line)).to eq(new_line)
        end
      end
    end

    context "without a diff file" do
      let(:diff_file) { nil }

      it "returns the same line number" do
        expect(subject.old_to_new(100)).to eq(100)
      end
    end
  end

  describe '#new_to_old' do
    context "with a diff file" do
      let(:mapping) do
        {
          1 => 1,
          2 => 2,
          3 => 3,
          4 => 4,
          5 => 5,
          6 => 6,
          7 => 7,
          8 => 8,
          # nil => 9,
          9 => nil,
          10 => 10,
          11 => 11,
          12 => 12,
          # nil => 13,
          # nil => 14,
          13 => nil,
          14 => nil,
          15 => nil,
          16 => nil,
          17 => nil,
          18 => nil,
          19 => nil,
          20 => nil,
          21 => 15,
          22 => 16,
          23 => 17,
          24 => 18,
          25 => 19,
          26 => 20,
          27 => 21,
          28 => nil,
          29 => 22,
          30 => 23,
          31 => 24,
          32 => 25,
          33 => 26,
          34 => 27,
          35 => 28,
          36 => 29,
          37 => 30
        }
      end

      it 'returns the old line number for the new line number' do
        mapping.each do |new_line, old_line|
          expect(subject.new_to_old(new_line)).to eq(old_line)
        end
      end
    end

    context "without a diff file" do
      let(:diff_file) { nil }

      it "returns the same line number" do
        expect(subject.new_to_old(100)).to eq(100)
      end
    end
  end
end
