# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Branch do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository.raw }

  subject { repository.branches }

  it { is_expected.to be_kind_of Array }

  describe '.find' do
    subject { described_class.find(repository, branch) }

    before do
      allow(repository).to receive(:find_branch).with(branch)
        .and_call_original
    end

    context 'when finding branch via branch name' do
      let(:branch) { 'master' }

      it 'returns a branch object' do
        expect(subject).to be_a(described_class)
        expect(subject.name).to eq(branch)

        expect(repository).to have_received(:find_branch).with(branch)
      end
    end

    context 'when the branch is already a branch' do
      let(:commit) { repository.commit('master') }
      let(:branch) { described_class.new(repository, 'master', commit.sha, commit) }

      it 'returns a branch object' do
        expect(subject).to be_a(described_class)
        expect(subject).to eq(branch)

        expect(repository).not_to have_received(:find_branch).with(branch)
      end
    end
  end

  describe "#cache_key" do
    subject { repository.branches.first }

    it "returns a cache key that changes based on changeable values" do
      digest = Digest::SHA1.hexdigest([subject.name, subject.target, subject.dereferenced_target.sha].join(":"))

      expect(subject.cache_key).to eq("branch:#{digest}")
    end
  end

  describe '#size' do
    subject { super().size }

    it { is_expected.to eq(TestEnv::BRANCH_SHA.size) }
  end

  describe 'first branch' do
    let(:branch) { repository.branches.first }

    it { expect(branch.name).to eq(TestEnv::BRANCH_SHA.keys.min) }
    it { expect(branch.dereferenced_target.sha).to start_with(TestEnv::BRANCH_SHA[TestEnv::BRANCH_SHA.keys.min]) }
  end

  describe 'master branch' do
    let(:branch) do
      repository.branches.find { |branch| branch.name == 'master' }
    end

    it { expect(branch.dereferenced_target.sha).to start_with(TestEnv::BRANCH_SHA['master']) }
  end

  context 'with active, stale and future branches' do
    let(:user) { create(:user) }
    let(:stale_sha) { travel_to(Gitlab::Git::Branch::STALE_BRANCH_THRESHOLD.ago - 5.days) { create_commit } }
    let(:active_sha) { travel_to(Gitlab::Git::Branch::STALE_BRANCH_THRESHOLD.ago + 5.days) { create_commit } }
    let(:future_sha) { travel_to(100.days.since) { create_commit } }

    before do
      repository.create_branch('stale-1', stale_sha)
      repository.create_branch('active-1', active_sha)
      repository.create_branch('future-1', future_sha)
    end

    describe 'examine if the branch is active or stale' do
      let(:stale_branch) { repository.find_branch('stale-1') }
      let(:active_branch) { repository.find_branch('active-1') }
      let(:future_branch) { repository.find_branch('future-1') }

      describe '#active?' do
        it { expect(stale_branch.active?).to be_falsey }
        it { expect(active_branch.active?).to be_truthy }
        it { expect(future_branch.active?).to be_truthy }
      end

      describe '#stale?' do
        it { expect(stale_branch.stale?).to be_truthy }
        it { expect(active_branch.stale?).to be_falsey }
        it { expect(future_branch.stale?).to be_falsey }
      end

      describe '#state' do
        it { expect(stale_branch.state).to eq(:stale) }
        it { expect(active_branch.state).to eq(:active) }
        it { expect(future_branch.state).to eq(:active) }
      end
    end
  end

  def create_commit
    repository.commit_files(
      user,
      branch_name: 'HEAD',
      message: 'commit message',
      actions: []
    ).newrev
  end
end
