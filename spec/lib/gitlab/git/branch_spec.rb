# frozen_string_literal: true

require "spec_helper"

describe Gitlab::Git::Branch, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
  let(:rugged) do
    Rugged::Repository.new(File.join(TestEnv.repos_path, repository.relative_path))
  end

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

  describe '#size' do
    subject { super().size }

    it { is_expected.to eq(SeedRepo::Repo::BRANCHES.size) }
  end

  describe 'first branch' do
    let(:branch) { repository.branches.first }

    it { expect(branch.name).to eq(SeedRepo::Repo::BRANCHES.first) }
    it { expect(branch.dereferenced_target.sha).to eq("0b4bc9a49b562e85de7cc9e834518ea6828729b9") }
  end

  describe 'master branch' do
    let(:branch) do
      repository.branches.find { |branch| branch.name == 'master' }
    end

    it { expect(branch.dereferenced_target.sha).to eq(SeedRepo::LastCommit::ID) }
  end

  context 'with active, stale and future branches' do
    let(:repository) do
      Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '', 'group/project')
    end

    let(:user) { create(:user) }
    let(:committer) { { email: user.email, name: user.name } }
    let(:params) do
      parents = [rugged.head.target]
      tree = parents.first.tree

      {
        message: +'commit message',
        author: committer,
        committer: committer,
        tree: tree,
        parents: parents
      }
    end
    let(:stale_sha) { Timecop.freeze(Gitlab::Git::Branch::STALE_BRANCH_THRESHOLD.ago - 5.days) { create_commit } }
    let(:active_sha) { Timecop.freeze(Gitlab::Git::Branch::STALE_BRANCH_THRESHOLD.ago + 5.days) { create_commit } }
    let(:future_sha) { Timecop.freeze(100.days.since) { create_commit } }

    before do
      repository.create_branch('stale-1', stale_sha)
      repository.create_branch('active-1', active_sha)
      repository.create_branch('future-1', future_sha)
    end

    after do
      ensure_seeds
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

  it { expect(repository.branches.size).to eq(SeedRepo::Repo::BRANCHES.size) }

  def create_commit
    params[:message].delete!(+"\r")
    Rugged::Commit.create(rugged, params.merge(committer: committer.merge(time: Time.now)))
  end
end
