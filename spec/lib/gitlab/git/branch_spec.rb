require "spec_helper"

describe Gitlab::Git::Branch, seed_helper: true do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }

  subject { repository.branches }

  it { is_expected.to be_kind_of Array }

  describe 'initialize' do
    let(:commit_id) { 'f00' }
    let(:commit_subject) { "My commit".force_encoding('ASCII-8BIT') }
    let(:committer) do
      Gitaly::FindLocalBranchCommitAuthor.new(
        name: generate(:name),
        email: generate(:email),
        date: Google::Protobuf::Timestamp.new(seconds: 123)
      )
    end
    let(:author) do
      Gitaly::FindLocalBranchCommitAuthor.new(
        name: generate(:name),
        email: generate(:email),
        date: Google::Protobuf::Timestamp.new(seconds: 456)
      )
    end
    let(:gitaly_branch) do
      Gitaly::FindLocalBranchResponse.new(
        name: 'foo', commit_id: commit_id, commit_subject: commit_subject,
        commit_author: author, commit_committer: committer
      )
    end
    let(:attributes) do
      {
        id: commit_id,
        message: commit_subject,
        authored_date: Time.at(author.date.seconds),
        author_name: author.name,
        author_email: author.email,
        committed_date: Time.at(committer.date.seconds),
        committer_name: committer.name,
        committer_email: committer.email
      }
    end
    let(:branch) { described_class.new(repository, 'foo', gitaly_branch) }

    it 'parses Gitaly::FindLocalBranchResponse correctly' do
      expect(Gitlab::Git::Commit).to receive(:decorate).
        with(hash_including(attributes)).and_call_original

      expect(branch.dereferenced_target.message.encoding).to be(Encoding::UTF_8)
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

  it { expect(repository.branches.size).to eq(SeedRepo::Repo::BRANCHES.size) }
end
