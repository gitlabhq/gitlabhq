require "spec_helper"

describe Gitlab::Git::Commit, seed_helper: true do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }
  let(:commit) { Gitlab::Git::Commit.find(repository, SeedRepo::Commit::ID) }
  let(:rugged_commit) do
    repository.rugged.lookup(SeedRepo::Commit::ID)
  end

  describe "Commit info" do
    before do
      repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH).rugged

      @committer = {
        email: 'mike@smith.com',
        name: "Mike Smith",
        time: Time.now
      }

      @author = {
        email: 'john@smith.com',
        name: "John Smith",
        time: Time.now
      }

      @parents = [repo.head.target]
      @gitlab_parents = @parents.map { |c| Gitlab::Git::Commit.decorate(c) }
      @tree = @parents.first.tree

      sha = Rugged::Commit.create(
        repo,
        author: @author,
        committer: @committer,
        tree: @tree,
        parents: @parents,
        message: "Refactoring specs",
        update_ref: "HEAD"
      )

      @raw_commit = repo.lookup(sha)
      @commit = Gitlab::Git::Commit.new(@raw_commit)
    end

    it { expect(@commit.short_id).to eq(@raw_commit.oid[0..10]) }
    it { expect(@commit.id).to eq(@raw_commit.oid) }
    it { expect(@commit.sha).to eq(@raw_commit.oid) }
    it { expect(@commit.safe_message).to eq(@raw_commit.message) }
    it { expect(@commit.created_at).to eq(@raw_commit.author[:time]) }
    it { expect(@commit.date).to eq(@raw_commit.committer[:time]) }
    it { expect(@commit.author_email).to eq(@author[:email]) }
    it { expect(@commit.author_name).to eq(@author[:name]) }
    it { expect(@commit.committer_name).to eq(@committer[:name]) }
    it { expect(@commit.committer_email).to eq(@committer[:email]) }
    it { expect(@commit.different_committer?).to be_truthy }
    it { expect(@commit.parents).to eq(@gitlab_parents) }
    it { expect(@commit.parent_id).to eq(@parents.first.oid) }
    it { expect(@commit.no_commit_message).to eq("--no commit message") }
    it { expect(@commit.tree).to eq(@tree) }

    after do
      # Erase the new commit so other tests get the original repo
      repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH).rugged
      repo.references.update("refs/heads/master", SeedRepo::LastCommit::ID)
    end
  end

  describe "Commit info from gitaly commit" do
    let(:id) { 'f00' }
    let(:subject) { "My commit".force_encoding('ASCII-8BIT') }
    let(:body) { subject + "My body".force_encoding('ASCII-8BIT') }
    let(:committer) do
      Gitaly::CommitAuthor.new(
        name: generate(:name),
        email: generate(:email),
        date: Google::Protobuf::Timestamp.new(seconds: 123)
      )
    end
    let(:author) do
      Gitaly::CommitAuthor.new(
        name: generate(:name),
        email: generate(:email),
        date: Google::Protobuf::Timestamp.new(seconds: 456)
      )
    end
    let(:gitaly_commit) do
      Gitaly::GitCommit.new(
        id: id,
        subject: subject,
        body: body,
        author: author,
        committer: committer
      )
    end
    let(:commit) { described_class.new(Gitlab::GitalyClient::Commit.new(repository, gitaly_commit)) }

    it { expect(commit.short_id).to eq(id[0..10]) }
    it { expect(commit.id).to eq(id) }
    it { expect(commit.sha).to eq(id) }
    it { expect(commit.safe_message).to eq(body) }
    it { expect(commit.created_at).to eq(Time.at(committer.date.seconds)) }
    it { expect(commit.author_email).to eq(author.email) }
    it { expect(commit.author_name).to eq(author.name) }
    it { expect(commit.committer_name).to eq(committer.name) }
    it { expect(commit.committer_email).to eq(committer.email) }

    context 'no body' do
      let(:body) { "".force_encoding('ASCII-8BIT') }

      it { expect(commit.safe_message).to eq(subject) }
    end
  end

  context 'Class methods' do
    describe '.find' do
      it "should return first head commit if without params" do
        expect(Gitlab::Git::Commit.last(repository).id).to eq(
          repository.rugged.head.target.oid
        )
      end

      it "should return valid commit" do
        expect(Gitlab::Git::Commit.find(repository, SeedRepo::Commit::ID)).to be_valid_commit
      end

      it "should return valid commit for tag" do
        expect(Gitlab::Git::Commit.find(repository, 'v1.0.0').id).to eq('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
      end

      it "should return nil for non-commit ids" do
        blob = Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "files/ruby/popen.rb")
        expect(Gitlab::Git::Commit.find(repository, blob.id)).to be_nil
      end

      it "should return nil for parent of non-commit object" do
        blob = Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "files/ruby/popen.rb")
        expect(Gitlab::Git::Commit.find(repository, "#{blob.id}^")).to be_nil
      end

      it "should return nil for nonexisting ids" do
        expect(Gitlab::Git::Commit.find(repository, "+123_4532530XYZ")).to be_nil
      end

      context 'with broken repo' do
        let(:repository) { Gitlab::Git::Repository.new('default', TEST_BROKEN_REPO_PATH) }

        it 'returns nil' do
          expect(Gitlab::Git::Commit.find(repository, SeedRepo::Commit::ID)).to be_nil
        end
      end
    end

    describe '.last_for_path' do
      context 'no path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, 'master') }

        describe '#id' do
          subject { super().id }
          it { is_expected.to eq(SeedRepo::LastCommit::ID) }
        end
      end

      context 'path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, 'master', 'files/ruby') }

        describe '#id' do
          subject { super().id }
          it { is_expected.to eq(SeedRepo::Commit::ID) }
        end
      end

      context 'ref + path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, SeedRepo::Commit::ID, 'encoding') }

        describe '#id' do
          subject { super().id }
          it { is_expected.to eq(SeedRepo::BigCommit::ID) }
        end
      end
    end

    describe '.where' do
      context 'path is empty string' do
        subject do
          commits = Gitlab::Git::Commit.where(
            repo: repository,
            ref: 'master',
            path: '',
            limit: 10
          )

          commits.map { |c| c.id }
        end

        it 'has 10 elements' do
          expect(subject.size).to eq(10)
        end
        it { is_expected.to include(SeedRepo::EmptyCommit::ID) }
      end

      context 'path is nil' do
        subject do
          commits = Gitlab::Git::Commit.where(
            repo: repository,
            ref: 'master',
            path: nil,
            limit: 10
          )

          commits.map { |c| c.id }
        end

        it 'has 10 elements' do
          expect(subject.size).to eq(10)
        end
        it { is_expected.to include(SeedRepo::EmptyCommit::ID) }
      end

      context 'ref is branch name' do
        subject do
          commits = Gitlab::Git::Commit.where(
            repo: repository,
            ref: 'master',
            path: 'files',
            limit: 3,
            offset: 1
          )

          commits.map { |c| c.id }
        end

        it 'has 3 elements' do
          expect(subject.size).to eq(3)
        end
        it { is_expected.to include("d14d6c0abdd253381df51a723d58691b2ee1ab08") }
        it { is_expected.not_to include("eb49186cfa5c4338011f5f590fac11bd66c5c631") }
      end

      context 'ref is commit id' do
        subject do
          commits = Gitlab::Git::Commit.where(
            repo: repository,
            ref: "874797c3a73b60d2187ed6e2fcabd289ff75171e",
            path: 'files',
            limit: 3,
            offset: 1
          )

          commits.map { |c| c.id }
        end

        it 'has 3 elements' do
          expect(subject.size).to eq(3)
        end
        it { is_expected.to include("2f63565e7aac07bcdadb654e253078b727143ec4") }
        it { is_expected.not_to include(SeedRepo::Commit::ID) }
      end

      context 'ref is tag' do
        subject do
          commits = Gitlab::Git::Commit.where(
            repo: repository,
            ref: 'v1.0.0',
            path: 'files',
            limit: 3,
            offset: 1
          )

          commits.map { |c| c.id }
        end

        it 'has 3 elements' do
          expect(subject.size).to eq(3)
        end
        it { is_expected.to include("874797c3a73b60d2187ed6e2fcabd289ff75171e") }
        it { is_expected.not_to include(SeedRepo::Commit::ID) }
      end
    end

    describe '.between' do
      subject do
        commits = Gitlab::Git::Commit.between(repository, SeedRepo::Commit::PARENT_ID, SeedRepo::Commit::ID)
        commits.map { |c| c.id }
      end

      it 'has 1 element' do
        expect(subject.size).to eq(1)
      end
      it { is_expected.to include(SeedRepo::Commit::ID) }
      it { is_expected.not_to include(SeedRepo::FirstCommit::ID) }
    end

    describe '.find_all' do
      shared_examples 'finding all commits' do
        it 'should return a return a collection of commits' do
          commits = described_class.find_all(repository)

          expect(commits).to all( be_a_kind_of(Gitlab::Git::Commit) )
        end

        context 'max_count' do
          subject do
            commits = Gitlab::Git::Commit.find_all(
              repository,
              max_count: 50
            )

            commits.map(&:id)
          end

          it 'has 34 elements' do
            expect(subject.size).to eq(34)
          end

          it 'includes the expected commits' do
            expect(subject).to include(
              SeedRepo::Commit::ID,
              SeedRepo::Commit::PARENT_ID,
              SeedRepo::FirstCommit::ID
            )
          end
        end

        context 'ref + max_count + skip' do
          subject do
            commits = Gitlab::Git::Commit.find_all(
              repository,
              ref: 'master',
              max_count: 50,
              skip: 1
            )

            commits.map(&:id)
          end

          it 'has 24 elements' do
            expect(subject.size).to eq(24)
          end

          it 'includes the expected commits' do
            expect(subject).to include(SeedRepo::Commit::ID, SeedRepo::FirstCommit::ID)
            expect(subject).not_to include(SeedRepo::LastCommit::ID)
          end
        end
      end

      context 'when Gitaly find_all_commits feature is enabled' do
        it_behaves_like 'finding all commits'
      end

      context 'when Gitaly find_all_commits feature is disabled', skip_gitaly_mock: true do
        it_behaves_like 'finding all commits'

        context 'while applying a sort order based on the `order` option' do
          it "allows ordering topologically (no parents shown before their children)" do
            expect_any_instance_of(Rugged::Walker).to receive(:sorting).with(Rugged::SORT_TOPO)

            described_class.find_all(repository, order: :topo)
          end

          it "allows ordering by date" do
            expect_any_instance_of(Rugged::Walker).to receive(:sorting).with(Rugged::SORT_DATE | Rugged::SORT_TOPO)

            described_class.find_all(repository, order: :date)
          end

          it "applies no sorting by default" do
            expect_any_instance_of(Rugged::Walker).to receive(:sorting).with(Rugged::SORT_NONE)

            described_class.find_all(repository)
          end
        end
      end
    end
  end

  describe '#init_from_rugged' do
    let(:gitlab_commit) { Gitlab::Git::Commit.new(rugged_commit) }
    subject { gitlab_commit }

    describe '#id' do
      subject { super().id }
      it { is_expected.to eq(SeedRepo::Commit::ID) }
    end
  end

  describe '#init_from_hash' do
    let(:commit) { Gitlab::Git::Commit.new(sample_commit_hash) }
    subject { commit }

    describe '#id' do
      subject { super().id }
      it { is_expected.to eq(sample_commit_hash[:id])}
    end

    describe '#message' do
      subject { super().message }
      it { is_expected.to eq(sample_commit_hash[:message])}
    end
  end

  describe '#stats' do
    subject { commit.stats }

    describe '#additions' do
      subject { super().additions }
      it { is_expected.to eq(11) }
    end

    describe '#deletions' do
      subject { super().deletions }
      it { is_expected.to eq(6) }
    end
  end

  describe '#to_diff' do
    subject { commit.to_diff }

    it { is_expected.not_to include "From #{SeedRepo::Commit::ID}" }
    it { is_expected.to include 'diff --git a/files/ruby/popen.rb b/files/ruby/popen.rb'}
  end

  describe '#has_zero_stats?' do
    it { expect(commit.has_zero_stats?).to eq(false) }
  end

  describe '#to_patch' do
    subject { commit.to_patch }

    it { is_expected.to include "From #{SeedRepo::Commit::ID}" }
    it { is_expected.to include 'diff --git a/files/ruby/popen.rb b/files/ruby/popen.rb'}
  end

  describe '#to_hash' do
    let(:hash) { commit.to_hash }
    subject { hash }

    it { is_expected.to be_kind_of Hash }

    describe '#keys' do
      subject { super().keys.sort }
      it { is_expected.to match(sample_commit_hash.keys.sort) }
    end
  end

  describe '#diffs' do
    subject { commit.diffs }

    it { is_expected.to be_kind_of Gitlab::Git::DiffCollection }
    it { expect(subject.count).to eq(2) }
    it { expect(subject.first).to be_kind_of Gitlab::Git::Diff }
  end

  describe '#ref_names' do
    let(:commit) { Gitlab::Git::Commit.find(repository, 'master') }
    subject { commit.ref_names(repository) }

    it 'has 1 element' do
      expect(subject.size).to eq(1)
    end
    it { is_expected.to include("master") }
    it { is_expected.not_to include("feature") }
  end

  def sample_commit_hash
    {
      author_email: "dmitriy.zaporozhets@gmail.com",
      author_name: "Dmitriy Zaporozhets",
      authored_date: "2012-02-27 20:51:12 +0200",
      committed_date: "2012-02-27 20:51:12 +0200",
      committer_email: "dmitriy.zaporozhets@gmail.com",
      committer_name: "Dmitriy Zaporozhets",
      id: SeedRepo::Commit::ID,
      message: "tree css fixes",
      parent_ids: ["874797c3a73b60d2187ed6e2fcabd289ff75171e"]
    }
  end
end
