# frozen_string_literal: true

require "spec_helper"

describe Gitlab::Git::Commit, :seed_helper do
  include GitHelpers

  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
  let(:rugged_repo) do
    Rugged::Repository.new(File.join(TestEnv.repos_path, TEST_REPO_PATH))
  end
  let(:commit) { described_class.find(repository, SeedRepo::Commit::ID) }
  let(:rugged_commit) { rugged_repo.lookup(SeedRepo::Commit::ID) }

  describe "Commit info" do
    before do
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

      @parents = [rugged_repo.head.target]
      @gitlab_parents = @parents.map { |c| described_class.find(repository, c.oid) }
      @tree = @parents.first.tree

      sha = Rugged::Commit.create(
        rugged_repo,
        author: @author,
        committer: @committer,
        tree: @tree,
        parents: @parents,
        message: "Refactoring specs",
        update_ref: "HEAD"
      )

      @raw_commit = rugged_repo.lookup(sha)
      @commit = described_class.find(repository, sha)
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

    after do
      # Erase the new commit so other tests get the original repo
      rugged_repo.references.update("refs/heads/master", SeedRepo::LastCommit::ID)
    end
  end

  describe "Commit info from gitaly commit" do
    let(:subject) { (+"My commit").force_encoding('ASCII-8BIT') }
    let(:body) { subject + (+"My body").force_encoding('ASCII-8BIT') }
    let(:body_size) { body.length }
    let(:gitaly_commit) { build(:gitaly_commit, subject: subject, body: body, body_size: body_size) }
    let(:id) { gitaly_commit.id }
    let(:committer) { gitaly_commit.committer }
    let(:author) { gitaly_commit.author }
    let(:commit) { described_class.new(repository, gitaly_commit) }

    it { expect(commit.short_id).to eq(id[0..10]) }
    it { expect(commit.id).to eq(id) }
    it { expect(commit.sha).to eq(id) }
    it { expect(commit.safe_message).to eq(body) }
    it { expect(commit.created_at).to eq(Time.at(committer.date.seconds)) }
    it { expect(commit.author_email).to eq(author.email) }
    it { expect(commit.author_name).to eq(author.name) }
    it { expect(commit.committer_name).to eq(committer.name) }
    it { expect(commit.committer_email).to eq(committer.email) }
    it { expect(commit.parent_ids).to eq(gitaly_commit.parent_ids) }

    context 'body_size != body.size' do
      let(:body) { (+"").force_encoding('ASCII-8BIT') }

      context 'zero body_size' do
        it { expect(commit.safe_message).to eq(subject) }
      end

      context 'body_size less than threshold' do
        let(:body_size) { 123 }

        it 'fetches commit message separately' do
          expect(described_class).to receive(:get_message).with(repository, id)

          commit.safe_message
        end
      end

      context 'body_size greater than threshold' do
        let(:body_size) { described_class::MAX_COMMIT_MESSAGE_DISPLAY_SIZE + 1 }

        it 'returns the suject plus a notice about message size' do
          expect(commit.safe_message).to eq("My commit\n\n--commit message is too big")
        end
      end
    end
  end

  context 'Class methods' do
    shared_examples '.find' do
      it "returns first head commit if without params" do
        expect(described_class.last(repository).id).to eq(
          rugged_repo.head.target.oid
        )
      end

      it "returns valid commit" do
        expect(described_class.find(repository, SeedRepo::Commit::ID)).to be_valid_commit
      end

      it "returns an array of parent ids" do
        expect(described_class.find(repository, SeedRepo::Commit::ID).parent_ids).to be_an(Array)
      end

      it "returns valid commit for tag" do
        expect(described_class.find(repository, 'v1.0.0').id).to eq('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
      end

      it "returns nil for non-commit ids" do
        blob = Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "files/ruby/popen.rb")
        expect(described_class.find(repository, blob.id)).to be_nil
      end

      it "returns nil for parent of non-commit object" do
        blob = Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "files/ruby/popen.rb")
        expect(described_class.find(repository, "#{blob.id}^")).to be_nil
      end

      it "returns nil for nonexisting ids" do
        expect(described_class.find(repository, "+123_4532530XYZ")).to be_nil
      end

      context 'with broken repo' do
        let(:repository) { Gitlab::Git::Repository.new('default', TEST_BROKEN_REPO_PATH, '', 'group/project') }

        it 'returns nil' do
          expect(described_class.find(repository, SeedRepo::Commit::ID)).to be_nil
        end
      end
    end

    describe '.find with Gitaly enabled' do
      it_should_behave_like '.find'
    end

    describe '.find with Rugged enabled', :enable_rugged do
      it 'calls out to the Rugged implementation' do
        allow_any_instance_of(Rugged).to receive(:rev_parse).with(SeedRepo::Commit::ID).and_call_original

        described_class.find(repository, SeedRepo::Commit::ID)
      end

      it_should_behave_like '.find'
    end

    describe '.last_for_path' do
      context 'no path' do
        subject { described_class.last_for_path(repository, 'master') }

        describe '#id' do
          subject { super().id }

          it { is_expected.to eq(SeedRepo::LastCommit::ID) }
        end
      end

      context 'path' do
        subject { described_class.last_for_path(repository, 'master', 'files/ruby') }

        describe '#id' do
          subject { super().id }

          it { is_expected.to eq(SeedRepo::Commit::ID) }
        end
      end

      context 'ref + path' do
        subject { described_class.last_for_path(repository, SeedRepo::Commit::ID, 'encoding') }

        describe '#id' do
          subject { super().id }

          it { is_expected.to eq(SeedRepo::BigCommit::ID) }
        end
      end
    end

    context 'path is empty string' do
      subject do
        commits = described_class.where(
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
        commits = described_class.where(
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
        commits = described_class.where(
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
        commits = described_class.where(
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
        commits = described_class.where(
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

    describe '.between' do
      subject do
        commits = described_class.between(repository, SeedRepo::Commit::PARENT_ID, SeedRepo::Commit::ID)
        commits.map { |c| c.id }
      end

      it 'has 1 element' do
        expect(subject.size).to eq(1)
      end
      it { is_expected.to include(SeedRepo::Commit::ID) }
      it { is_expected.not_to include(SeedRepo::FirstCommit::ID) }
    end

    describe '.shas_with_signatures' do
      let(:signed_shas) { %w[5937ac0a7beb003549fc5fd26fc247adbce4a52e 570e7b2abdd848b95f2f578043fc23bd6f6fd24d] }
      let(:unsigned_shas) { %w[19e2e9b4ef76b422ce1154af39a91323ccc57434 c642fe9b8b9f28f9225d7ea953fe14e74748d53b] }
      let(:first_signed_shas) { %w[5937ac0a7beb003549fc5fd26fc247adbce4a52e c642fe9b8b9f28f9225d7ea953fe14e74748d53b] }

      it 'has 2 signed shas' do
        ret = described_class.shas_with_signatures(repository, signed_shas)
        expect(ret).to eq(signed_shas)
      end

      it 'has 0 signed shas' do
        ret = described_class.shas_with_signatures(repository, unsigned_shas)
        expect(ret).to eq([])
      end

      it 'has 1 signed sha' do
        ret = described_class.shas_with_signatures(repository, first_signed_shas)
        expect(ret).to contain_exactly(first_signed_shas.first)
      end
    end

    describe '.find_all' do
      it 'returns a return a collection of commits' do
        commits = described_class.find_all(repository)

        expect(commits).to all( be_a_kind_of(described_class) )
      end

      context 'max_count' do
        subject do
          commits = described_class.find_all(
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
          commits = described_class.find_all(
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

    shared_examples '.batch_by_oid' do
      context 'with multiple OIDs' do
        let(:oids) { [SeedRepo::Commit::ID, SeedRepo::FirstCommit::ID] }

        it 'returns multiple commits' do
          commits = described_class.batch_by_oid(repository, oids)

          expect(commits.count).to eq(2)
          expect(commits).to all( be_a(Gitlab::Git::Commit) )
          expect(commits.first.sha).to eq(SeedRepo::Commit::ID)
          expect(commits.second.sha).to eq(SeedRepo::FirstCommit::ID)
        end
      end

      context 'when oids is empty' do
        it 'returns empty commits' do
          commits = described_class.batch_by_oid(repository, [])

          expect(commits.count).to eq(0)
        end
      end
    end

    describe '.batch_by_oid with Gitaly enabled' do
      it_should_behave_like '.batch_by_oid'

      context 'when oids is empty' do
        it 'makes no Gitaly request' do
          expect(Gitlab::GitalyClient).not_to receive(:call).with(repository.storage, :commit_service, :list_commits_by_oid)

          described_class.batch_by_oid(repository, [])
        end
      end
    end

    describe '.batch_by_oid with Rugged enabled', :enable_rugged do
      it_should_behave_like '.batch_by_oid'

      it 'calls out to the Rugged implementation' do
        allow_any_instance_of(Rugged).to receive(:rev_parse).with(SeedRepo::Commit::ID).and_call_original

        described_class.batch_by_oid(repository, [SeedRepo::Commit::ID])
      end
    end

    describe '.extract_signature_lazily' do
      subject { described_class.extract_signature_lazily(repository, commit_id).itself }

      context 'when the commit is signed' do
        let(:commit_id) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }

        it 'returns signature and signed text' do
          signature, signed_text = subject

          expected_signature = <<~SIGNATURE
            -----BEGIN PGP SIGNATURE-----
            Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
            Comment: GPGTools - https://gpgtools.org

            iQEcBAABCgAGBQJTDvaZAAoJEGJ8X1ifRn8XfvYIAMuB0yrbTGo1BnOSoDfyrjb0
            Kw2EyUzvXYL72B63HMdJ+/0tlSDC6zONF3fc+bBD8z+WjQMTbwFNMRbSSy2rKEh+
            mdRybOP3xBIMGgEph0/kmWln39nmFQBsPRbZBWoU10VfI/ieJdEOgOphszgryRar
            TyS73dLBGE9y9NIININVaNISet9D9QeXFqc761CGjh4YIghvPpi+YihMWapGka6v
            hgKhX+hc5rj+7IEE0CXmlbYR8OYvAbAArc5vJD7UTxAY4Z7/l9d6Ydt9GQ25khfy
            ANFgltYzlR6evLFmDjssiP/mx/ZMN91AL0ueJ9nNGv411Mu2CUW+tDCaQf35mdc=
            =j51i
            -----END PGP SIGNATURE-----
          SIGNATURE

          expect(signature).to eq(expected_signature.chomp)
          expect(signature).to be_a_binary_string

          expected_signed_text = <<~SIGNED_TEXT
            tree 22bfa2fbd217df24731f43ff43a4a0f8db759dae
            parent ae73cb07c9eeaf35924a10f713b364d32b2dd34f
            author Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com> 1393489561 +0200
            committer Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com> 1393489561 +0200

            Feature added

            Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          SIGNED_TEXT

          expect(signed_text).to eq(expected_signed_text)
          expect(signed_text).to be_a_binary_string
        end
      end

      context 'when the commit has no signature' do
        let(:commit_id) { '4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6' }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when the commit cannot be found' do
        let(:commit_id) { Gitlab::Git::BLANK_SHA }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when the commit ID is invalid' do
        let(:commit_id) { '4b4918a572fa86f9771e5ba40fbd48e' }

        it 'raises ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when loading signatures in batch once' do
        it 'fetches signatures in batch once' do
          commit_ids = %w[0b4bc9a49b562e85de7cc9e834518ea6828729b9 4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6]
          signatures = commit_ids.map do |commit_id|
            described_class.extract_signature_lazily(repository, commit_id)
          end

          other_repository = double(:repository)
          described_class.extract_signature_lazily(other_repository, commit_ids.first)

          expect(described_class).to receive(:batch_signature_extraction)
            .with(repository, commit_ids)
            .once
            .and_return({})

          expect(described_class).not_to receive(:batch_signature_extraction)
            .with(other_repository, commit_ids.first)

          2.times { signatures.each(&:itself) }
        end
      end
    end
  end

  skip 'move this test to gitaly-ruby' do
    describe '#init_from_rugged' do
      let(:gitlab_commit) { described_class.new(repository, rugged_commit) }
      subject { gitlab_commit }

      describe '#id' do
        subject { super().id }
        it { is_expected.to eq(SeedRepo::Commit::ID) }
      end
    end
  end

  describe '#init_from_hash' do
    let(:commit) { described_class.new(repository, sample_commit_hash) }
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

    describe '#total' do
      subject { super().total }

      it { is_expected.to eq(17) }
    end
  end

  describe '#gitaly_commit?' do
    context 'when the commit data comes from gitaly' do
      it { expect(commit.gitaly_commit?).to eq(true) }
    end

    context 'when the commit data comes from a Hash' do
      let(:commit) { described_class.new(repository, sample_commit_hash) }

      it { expect(commit.gitaly_commit?).to eq(false) }
    end
  end

  describe '#has_zero_stats?' do
    it { expect(commit.has_zero_stats?).to eq(false) }
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
    let(:commit) { described_class.find(repository, 'master') }
    subject { commit.ref_names(repository) }

    it 'has 2 element' do
      expect(subject.size).to eq(2)
    end
    it { is_expected.to include("master") }
    it { is_expected.not_to include("feature") }
  end

  describe '.get_message' do
    let(:commit_ids) { %w[6d394385cf567f80a8fd85055db1ab4c5295806f cfe32cf61b73a0d5e9f13e774abde7ff789b1660] }

    subject do
      commit_ids.map { |id| described_class.get_message(repository, id) }
    end

    it 'gets commit messages' do
      expect(subject).to contain_exactly(
        "Added contributing guide\n\nSigned-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>\n",
        "Add submodule\n\nSigned-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>\n"
      )
    end

    it 'gets messages in one batch', :request_store do
      expect { subject.map(&:itself) }.to change { Gitlab::GitalyClient.get_request_count }.by(1)
    end
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
