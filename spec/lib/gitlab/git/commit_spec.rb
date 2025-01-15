# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Commit, feature_category: :source_code_management do
  let_it_be(:repository) { create(:project, :repository).repository.raw }
  let(:commit) { described_class.find(repository, SeedRepo::Commit::ID) }

  describe "Commit info from gitaly commit" do
    let(:subject) { (+"My commit").force_encoding('ASCII-8BIT') }
    let(:body_size) { body.length }
    let(:gitaly_commit) { build(:gitaly_commit, subject: subject, body: body, body_size: body_size, tree_id: tree_id) }
    let(:id) { gitaly_commit.id }
    let(:tree_id) { 'd7f32d821c9cc7b1a9166ca7c4ba95b5c2d0d000' }
    let(:committer) { gitaly_commit.committer }
    let(:author) { gitaly_commit.author }
    let(:commit) { described_class.new(repository, gitaly_commit) }

    let(:body) do
      body = +<<~BODY
        Bleep bloop.

        Cc: John Doe <johndoe@gitlab.com>
        Cc: Jane Doe <janedoe@gitlab.com>
      BODY

      [subject, "\n", body].join.force_encoding("ASCII-8BIT")
    end

    it { expect(commit.short_id).to eq(id[0..10]) }
    it { expect(commit.id).to eq(id) }
    it { expect(commit.sha).to eq(id) }
    it { expect(commit.safe_message).to eq(body) }
    it { expect(commit.created_at).to eq(Time.at(committer.date.seconds).utc) }
    it { expect(commit.author_email).to eq(author.email) }
    it { expect(commit.author_name).to eq(author.name) }
    it { expect(commit.committer_name).to eq(committer.name) }
    it { expect(commit.committer_email).to eq(committer.email) }
    it { expect(commit.parent_ids).to eq(gitaly_commit.parent_ids) }
    it { expect(commit.tree_id).to eq(tree_id) }

    it "parses the commit trailers" do
      expect(commit.trailers).to eq(
        { "Cc" => "Jane Doe <janedoe@gitlab.com>" }
      )
    end

    it "parses the extended commit trailers" do
      expect(commit.extended_trailers).to eq(
        { "Cc" => ["John Doe <johndoe@gitlab.com>", "Jane Doe <janedoe@gitlab.com>"] }
      )
    end

    context 'non-ASCII content' do
      let(:body) do
        body = +<<~BODY
          Äpfel

          Changelog: Äpfel
        BODY

        [subject, "\n", body.force_encoding("ASCII-8BIT")].join
      end

      it "parses non-ASCII commit trailers" do
        expect(commit.trailers).to eq(
          { 'Changelog' => 'Äpfel' }
        )
      end

      it "parses non-ASCII extended commit trailers" do
        expect(commit.extended_trailers).to eq(
          { 'Changelog' => ['Äpfel'] }
        )
      end
    end

    context 'non-UTC dates' do
      let(:seconds) { Time.now.to_i }

      it 'sets timezones correctly' do
        gitaly_commit.author.date.seconds = seconds
        gitaly_commit.author.timezone = '-0800'
        gitaly_commit.committer.date.seconds = seconds
        gitaly_commit.committer.timezone = '+0800'

        expect(commit.authored_date).to eq(Time.at(seconds, in: '-08:00'))
        expect(commit.committed_date).to eq(Time.at(seconds, in: '+08:00'))
      end
    end

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

        it 'returns the subject plus a notice about message size' do
          expect(commit.safe_message).to eq("My commit\n\n--commit message is too big")
        end
      end

      context "large commit message" do
        let(:user) { create(:user) }
        let(:sha) { create_commit_with_large_message }
        let(:commit) { repository.commit(sha) }

        def create_commit_with_large_message
          repository.commit_files(
            user,
            branch_name: 'HEAD',
            message: "Repeat " * 10 * 1024,
            actions: []
          ).newrev
        end

        it 'returns a String' do
          # When #message is called, its encoding is forced from
          # ASCII-8BIT to UTF-8, and the method returns a
          # string. Calling #message again may cause BatchLoader to
          # return since the encoding has been modified to UTF-8, and
          # the encoding helper will return the original object unmodified.
          #
          # To ensure #fetch_body_from_gitaly returns a String, invoke
          # #to_s. In the test below, do a strict type check to ensure
          # that a String is always returned. Note that the Rspec
          # matcher be_instance_of(String) appears to evaluate the
          # BatchLoader result, so we have to do a strict comparison
          # here.
          2.times { expect(String === commit.message).to be true }
        end
      end
    end
  end

  context 'Class methods' do
    shared_examples '.find' do
      it "returns first head commit if without params" do
        expect(described_class.last(repository).id).to eq(
          repository.commit.sha
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

      it "returns nil for id started with dash" do
        expect(described_class.find(repository, "-HEAD")).to be_nil
      end

      it "returns nil for id containing colon" do
        expect(described_class.find(repository, "HEAD:")).to be_nil
      end

      it "returns nil for id containing space" do
        expect(described_class.find(repository, "HE AD")).to be_nil
      end

      it "returns nil for id containing tab" do
        expect(described_class.find(repository, "HE\tAD")).to be_nil
      end

      it "returns nil for id containing NULL" do
        expect(described_class.find(repository, "HE\x00AD")).to be_nil
      end
    end

    describe '.find with Gitaly enabled' do
      it_behaves_like '.find'
    end

    describe '.last_for_path' do
      context 'no path' do
        subject { described_class.last_for_path(repository, 'master') }

        describe '#id' do
          subject { super().id }

          it { is_expected.to eq(TestEnv::BRANCH_SHA['master']) }
        end
      end

      context 'path' do
        subject { described_class.last_for_path(repository, 'master', 'files/ruby') }

        describe '#id' do
          subject { super().id }

          it { is_expected.to eq(SeedRepo::Commit::ID) }
        end
      end

      context 'pathspec' do
        let(:pathspec) { 'files/ruby/*' }

        context 'with default literal_pathspec value' do
          it 'finds the seed commit' do
            commit = described_class.last_for_path(repository, 'master', pathspec)

            expect(commit.id).to eq(SeedRepo::Commit::ID)
          end
        end

        context 'with literal_pathspec set to false' do
          it 'finds the seed commit' do
            commit = described_class.last_for_path(repository, 'master', pathspec, literal_pathspec: false)

            expect(commit.id).to eq(SeedRepo::Commit::ID)
          end
        end

        context 'with literal_pathspec set to true' do
          it 'does not find the seed commit' do
            commit = described_class.last_for_path(repository, 'master', pathspec, literal_pathspec: true)

            expect(commit).to be_nil
          end
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

      it { is_expected.to include(TestEnv::BRANCH_SHA['master']) }
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

      it { is_expected.to include(TestEnv::BRANCH_SHA['master']) }
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
      let(:limit) { nil }
      let(:commit_ids) { commits.map(&:id) }

      subject(:commits) { described_class.between(repository, from, to, limit: limit) }

      context 'requesting a single commit' do
        let(:from) { SeedRepo::Commit::PARENT_ID }
        let(:to) { SeedRepo::Commit::ID }

        it { expect(commit_ids).to contain_exactly(to) }
      end

      context 'requesting a commit range' do
        let(:from) { 'v1.0.0' }
        let(:to) { 'v1.1.0' }

        let(:commits_in_range) do
          %w[
            570e7b2abdd848b95f2f578043fc23bd6f6fd24d
            5937ac0a7beb003549fc5fd26fc247adbce4a52e
          ]
        end

        context 'no limit' do
          it { expect(commit_ids).to eq(commits_in_range) }
        end

        context 'limited' do
          let(:limit) { 1 }

          it { expect(commit_ids).to eq(commits_in_range.last(1)) }
        end
      end
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
      it 'returns a collection of commits' do
        commits = described_class.find_all(repository)

        expect(commits).to all(be_a_kind_of(described_class))
      end

      context 'max_count' do
        subject do
          commits = described_class.find_all(
            repository,
            max_count: 50
          )

          commits.map(&:id)
        end

        it 'has maximum elements' do
          expect(subject.size).to eq(50)
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

        it 'has 36 elements' do
          expect(subject.size).to eq(36)
        end

        it 'includes the expected commits' do
          expect(subject).to include(SeedRepo::Commit::ID, SeedRepo::FirstCommit::ID)
          expect(subject).not_to include(TestEnv::BRANCH_SHA['master'])
        end
      end
    end

    describe '.list_all' do
      subject(:commits) do
        described_class.list_all(
          repository,
          ref: 'master',
          revisions: %w[--branches --tags],
          order: :date,
          reverse: false,
          pagination_params: { limit: 4 }
        )
      end

      context 'with refname and revisions' do
        it 'returns a collection of commits' do
          expect(commits).to all(be_a_kind_of(described_class))
        end

        it 'returns all commits ordered by date and starting from the refname' do
          expect(commits.first.id).to eq('ba3343bc4fa403a8dfbfcab7fc1a8c29ee34bd69')
        end
      end

      context 'with commit sha ref and revisions' do
        let(:committed_date) { Time.parse('2019-11-07T13:24:47.000+01:00').utc }
        let(:commit_sha) { 'ed775cc81e5477df30c2abba7b6fdbb5d0baadae' }

        subject(:commits) do
          described_class.list_all(
            repository,
            ref: commit_sha,
            revisions: %w[--branches --tags],
            order: :date,
            reverse: false,
            before: committed_date,
            pagination_params: { limit: 5 }
          )
        end

        it 'returns a collection of commits' do
          expect(commits).to all(be_a_kind_of(described_class))
        end

        it 'returns all commits ordered by date and starting from the commit sha' do
          expect(commits.first.id).to eq('ed775cc81e5477df30c2abba7b6fdbb5d0baadae')
        end
      end
    end

    shared_examples '.batch_by_oid' do
      context 'with multiple OIDs' do
        let(:oids) { [SeedRepo::Commit::ID, SeedRepo::FirstCommit::ID] }

        it 'returns multiple commits' do
          commits = described_class.batch_by_oid(repository, oids)

          expect(commits.count).to eq(2)
          expect(commits).to all(be_a(described_class))
          expect(commits.first.sha).to eq(SeedRepo::Commit::ID)
          expect(commits.second.sha).to eq(SeedRepo::FirstCommit::ID)
        end

        context 'when repo does not exist' do
          let(:no_repository) { Gitlab::Git::Repository.new('default', '@does-not-exist/project', '', 'bogus/project') }

          it 'returns empty commits' do
            commits = described_class.batch_by_oid(no_repository, oids)

            expect(commits.count).to eq(0)
          end
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
      it_behaves_like '.batch_by_oid'

      context 'when oids is empty' do
        it 'makes no Gitaly request' do
          expect(Gitlab::GitalyClient).not_to receive(:call).with(repository.storage, :commit_service, :list_commits_by_oid)

          described_class.batch_by_oid(repository, [])
        end
      end
    end

    describe '.extract_signature_lazily' do
      subject { described_class.extract_signature_lazily(repository, commit_id).itself }

      context 'when the commit is signed' do
        let(:commit_id) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }

        it 'returns signature and signed text' do
          signature, signed_text, signer = subject.values_at(:signature, :signed_text, :signer)

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
          expect(signer).to eq(:SIGNER_USER)
        end
      end

      context 'when the commit has no signature' do
        let(:commit_id) { '4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6' }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when the commit cannot be found' do
        let(:commit_id) { Gitlab::Git::SHA1_BLANK_SHA }

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

  describe '#init_from_hash' do
    let(:commit) { described_class.new(repository, sample_commit_hash) }

    subject { commit }

    describe '#id' do
      subject { super().id }

      it { is_expected.to eq(sample_commit_hash[:id]) }
    end

    describe '#message' do
      subject { super().message }

      it { is_expected.to eq(sample_commit_hash[:message]) }
    end

    describe '#tree_id' do
      subject { super().tree_id }

      it "doesn't return tree id for non-Gitaly commits" do
        is_expected.to be_nil
      end
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

    it 'has 3 elements' do
      expect(subject.size).to eq(3)
    end

    it { is_expected.to include("master") }
    it { is_expected.not_to include("feature") }
  end

  describe '#first_ref_by_oid' do
    let(:commit) { described_class.find(repository, 'master') }

    subject { commit.first_ref_by_oid(repository) }

    it { is_expected.to eq("master") }
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
      repository # preload repository so that the project factory does not pollute request counts

      expect { subject.map(&:itself) }.to change { Gitlab::GitalyClient.get_request_count }.by(1)
    end
  end

  describe 'SHA patterns' do
    shared_examples 'a SHA-matching pattern' do
      let(:expected_match) { sha }

      shared_examples 'a match' do
        it 'matches the pattern' do
          expect(value).to match(pattern)
          expect(pattern.match(value).to_a).to eq([expected_match])
        end
      end

      shared_examples 'no match' do
        it 'does not match the pattern' do
          expect(value).not_to match(pattern)
        end
      end

      shared_examples 'a SHA pattern' do
        context "with too short value" do
          let(:value) { sha[0, described_class::MIN_SHA_LENGTH - 1] }

          it_behaves_like 'no match'
        end

        context "with full length" do
          let(:value) { sha }

          it_behaves_like 'a match'
        end

        context "with exceeeding length" do
          let(:value) { sha + sha }

          # This case is not exactly pretty for SHA1 as we would still match the full SHA256 length. It's arguable what
          # the correct behaviour would be, but without starting to distinguish SHA1 and SHA256 hashes this is the best
          # we can do.
          let(:expected_match) { (sha + sha)[0, described_class::MAX_SHA_LENGTH] }

          it_behaves_like 'a match'
        end

        context "with embedded SHA" do
          let(:value) { "xxx#{sha}xxx" }

          it_behaves_like 'a match'
        end
      end

      context 'abbreviated SHA pattern' do
        let(:pattern) { described_class::SHA_PATTERN }

        context "with minimum length" do
          let(:value) { sha[0, described_class::MIN_SHA_LENGTH] }
          let(:expected_match) { value }

          it_behaves_like 'a match'
        end

        context "with medium length" do
          let(:value) { sha[0, described_class::MIN_SHA_LENGTH + 20] }
          let(:expected_match) { value }

          it_behaves_like 'a match'
        end

        it_behaves_like 'a SHA pattern'
      end

      context 'full SHA pattern' do
        let(:pattern) { described_class::FULL_SHA_PATTERN }

        context 'with abbreviated length' do
          let(:value) { sha[0, described_class::SHA1_LENGTH - 1] }

          it_behaves_like 'no match'
        end

        it_behaves_like 'a SHA pattern'
      end
    end

    context 'SHA1' do
      let(:sha) { "5716ca5987cbf97d6bb54920bea6adde242d87e6" }

      it_behaves_like 'a SHA-matching pattern'
    end

    context 'SHA256' do
      let(:sha) { "a52e146ac2ab2d0efbb768ab8ebd1e98a6055764c81fe424fbae4522f5b4cb92" }

      it_behaves_like 'a SHA-matching pattern'
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
      parent_ids: ["874797c3a73b60d2187ed6e2fcabd289ff75171e"],
      trailers: {},
      extended_trailers: {},
      referenced_by: []
    }
  end
end
