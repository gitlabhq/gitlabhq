# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Tree, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }

  shared_examples :repo do
    let(:tree) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID) }

    it { expect(tree).to be_kind_of Array }
    it { expect(tree.empty?).to be_falsey }
    it { expect(tree.count(&:dir?)).to eq(2) }
    it { expect(tree.count(&:file?)).to eq(10) }
    it { expect(tree.count(&:submodule?)).to eq(2) }

    it 'returns an empty array when called with an invalid ref' do
      expect(described_class.where(repository, 'foobar-does-not-exist')).to eq([])
    end

    it 'returns a list of tree objects' do
      entries = described_class.where(repository, SeedRepo::Commit::ID, 'files', true)

      expect(entries.map(&:path)).to include('files/html',
                                             'files/markdown/ruby-style-guide.md')
      expect(entries.count).to be >= 10
      expect(entries).to all(be_a(Gitlab::Git::Tree))
    end

    describe '#dir?' do
      let(:dir) { tree.select(&:dir?).first }

      it { expect(dir).to be_kind_of Gitlab::Git::Tree }
      it { expect(dir.id).to eq('3c122d2b7830eca25235131070602575cf8b41a1') }
      it { expect(dir.commit_id).to eq(SeedRepo::Commit::ID) }
      it { expect(dir.name).to eq('encoding') }
      it { expect(dir.path).to eq('encoding') }
      it { expect(dir.mode).to eq('40000') }
      it { expect(dir.flat_path).to eq('encoding') }

      context :subdir do
        # rubocop: disable Rails/FindBy
        # This is not ActiveRecord where..first
        let(:subdir) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files').first }
        # rubocop: enable Rails/FindBy

        it { expect(subdir).to be_kind_of Gitlab::Git::Tree }
        it { expect(subdir.id).to eq('a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba') }
        it { expect(subdir.commit_id).to eq(SeedRepo::Commit::ID) }
        it { expect(subdir.name).to eq('html') }
        it { expect(subdir.path).to eq('files/html') }
        it { expect(subdir.flat_path).to eq('files/html') }
      end

      context :subdir_file do
        # rubocop: disable Rails/FindBy
        # This is not ActiveRecord where..first
        let(:subdir_file) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files/ruby').first }
        # rubocop: enable Rails/FindBy

        it { expect(subdir_file).to be_kind_of Gitlab::Git::Tree }
        it { expect(subdir_file.id).to eq('7e3e39ebb9b2bf433b4ad17313770fbe4051649c') }
        it { expect(subdir_file.commit_id).to eq(SeedRepo::Commit::ID) }
        it { expect(subdir_file.name).to eq('popen.rb') }
        it { expect(subdir_file.path).to eq('files/ruby/popen.rb') }
        it { expect(subdir_file.flat_path).to eq('files/ruby/popen.rb') }
      end

      context :flat_path do
        let(:filename) { 'files/flat/path/correct/content.txt' }
        let(:oid) { create_file(filename) }
        # rubocop: disable Rails/FindBy
        # This is not ActiveRecord where..first
        let(:subdir_file) { Gitlab::Git::Tree.where(repository, oid, 'files/flat').first }
        # rubocop: enable Rails/FindBy
        let(:repository_rugged) { Rugged::Repository.new(File.join(SEED_STORAGE_PATH, TEST_REPO_PATH)) }

        it { expect(subdir_file.flat_path).to eq('files/flat/path/correct') }
      end

      def create_file(path)
        oid = repository_rugged.write('test', :blob)
        index = repository_rugged.index
        index.add(path: filename, oid: oid, mode: 0100644)

        options = commit_options(
          repository_rugged,
          index,
          repository_rugged.head.target,
          'HEAD',
          'Add new file')

        Rugged::Commit.create(repository_rugged, options)
      end

      # Build the options hash that's passed to Rugged::Commit#create
      def commit_options(repo, index, target, ref, message)
        options = {}
        options[:tree] = index.write_tree(repo)
        options[:author] = {
          email: "test@example.com",
          name: "Test Author",
          time: Time.gm(2014, "mar", 3, 20, 15, 1)
        }
        options[:committer] = {
          email: "test@example.com",
          name: "Test Author",
          time: Time.gm(2014, "mar", 3, 20, 15, 1)
        }
        options[:message] ||= message
        options[:parents] = repo.empty? ? [] : [target].compact
        options[:update_ref] = ref

        options
      end
    end

    describe '#file?' do
      let(:file) { tree.select(&:file?).first }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { expect(file.id).to eq('dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82') }
      it { expect(file.commit_id).to eq(SeedRepo::Commit::ID) }
      it { expect(file.name).to eq('.gitignore') }
    end

    describe '#readme?' do
      let(:file) { tree.select(&:readme?).first }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { expect(file.name).to eq('README.md') }
    end

    describe '#contributing?' do
      let(:file) { tree.select(&:contributing?).first }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { expect(file.name).to eq('CONTRIBUTING.md') }
    end

    describe '#submodule?' do
      let(:submodule) { tree.select(&:submodule?).first }

      it { expect(submodule).to be_kind_of Gitlab::Git::Tree }
      it { expect(submodule.id).to eq('79bceae69cb5750d6567b223597999bfa91cb3b9') }
      it { expect(submodule.commit_id).to eq('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
      it { expect(submodule.name).to eq('gitlab-shell') }
    end
  end

  describe '.where with Gitaly enabled' do
    it_behaves_like :repo
  end

  describe '.where with Rugged enabled', :enable_rugged do
    it 'calls out to the Rugged implementation' do
      allow_next_instance_of(Rugged) do |instance|
        allow(instance).to receive(:lookup).with(SeedRepo::Commit::ID)
      end

      described_class.where(repository, SeedRepo::Commit::ID, 'files', false)
    end

    it_behaves_like :repo
  end
end
