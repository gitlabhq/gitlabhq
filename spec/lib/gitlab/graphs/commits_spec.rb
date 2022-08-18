# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphs::Commits do
  let!(:project) { create(:project, :public) }

  let!(:commit1) { create(:commit, git_commit: RepoHelpers.sample_commit, project: project, committed_date: Time.now) }
  let!(:commit1_yesterday) { create(:commit, git_commit: RepoHelpers.sample_commit, project: project, committed_date: 1.day.ago) }

  let!(:commit2) { create(:commit, git_commit: RepoHelpers.another_sample_commit, project: project, committed_date: Time.now) }

  describe '#commit_per_day' do
    context 'when range is only commits from today' do
      subject { described_class.new([commit2, commit1]).commit_per_day }

      it { is_expected.to eq 2 }
    end
  end

  context 'when range is only commits from today' do
    subject { described_class.new([commit2, commit1]) }

    describe '#commit_per_day' do
      it { expect(subject.commit_per_day).to eq 2 }
    end

    describe '#duration' do
      it { expect(subject.duration).to eq 0 }
    end
  end

  context 'with commits from yesterday and today' do
    subject { described_class.new([commit2, commit1_yesterday]) }

    describe '#commit_per_day' do
      it { expect(subject.commit_per_day).to eq 1.0 }
    end

    describe '#duration' do
      it { expect(subject.duration).to eq 1 }
    end
  end
end
