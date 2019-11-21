# frozen_string_literal: true

require "spec_helper"

describe Gitlab::Git::Compare, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
  let(:compare) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, SeedRepo::Commit::ID, straight: false) }
  let(:compare_straight) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, SeedRepo::Commit::ID, straight: true) }

  describe '#commits' do
    subject do
      compare.commits.map(&:id)
    end

    it 'has 8 elements' do
      expect(subject.size).to eq(8)
    end

    it { is_expected.to include(SeedRepo::Commit::PARENT_ID) }
    it { is_expected.not_to include(SeedRepo::BigCommit::PARENT_ID) }

    context 'non-existing base ref' do
      let(:compare) { Gitlab::Git::Compare.new(repository, 'no-such-branch', SeedRepo::Commit::ID) }

      it { is_expected.to be_empty }
    end

    context 'non-existing head ref' do
      let(:compare) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, '1234567890') }

      it { is_expected.to be_empty }
    end

    context 'base ref is equal to head ref' do
      let(:compare) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, SeedRepo::BigCommit::ID) }

      it { is_expected.to be_empty }
    end

    context 'providing nil as base ref or head ref' do
      let(:compare) { Gitlab::Git::Compare.new(repository, nil, nil) }

      it { is_expected.to be_empty }
    end
  end

  describe '#diffs' do
    subject do
      compare.diffs.map(&:new_path)
    end

    it 'has 10 elements' do
      expect(subject.size).to eq(10)
    end

    it { is_expected.to include('files/ruby/popen.rb') }
    it { is_expected.not_to include('LICENSE') }

    context 'non-existing base ref' do
      let(:compare) { Gitlab::Git::Compare.new(repository, 'no-such-branch', SeedRepo::Commit::ID) }

      it { is_expected.to be_empty }
    end

    context 'non-existing head ref' do
      let(:compare) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, '1234567890') }

      it { is_expected.to be_empty }
    end
  end

  describe '#same' do
    subject do
      compare.same
    end

    it { is_expected.to eq(false) }

    context 'base ref is equal to head ref' do
      let(:compare) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, SeedRepo::BigCommit::ID) }

      it { is_expected.to eq(true) }
    end
  end

  describe '#commits', 'straight compare' do
    subject do
      compare_straight.commits.map(&:id)
    end

    it 'has 8 elements' do
      expect(subject.size).to eq(8)
    end

    it { is_expected.to include(SeedRepo::Commit::PARENT_ID) }
    it { is_expected.not_to include(SeedRepo::BigCommit::PARENT_ID) }
  end

  describe '#diffs', 'straight compare' do
    subject do
      compare_straight.diffs.map(&:new_path)
    end

    it 'has 10 elements' do
      expect(subject.size).to eq(10)
    end

    it { is_expected.to include('files/ruby/popen.rb') }
    it { is_expected.not_to include('LICENSE') }
  end
end
