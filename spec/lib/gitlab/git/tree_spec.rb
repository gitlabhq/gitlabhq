require "spec_helper"

describe Gitlab::Git::Tree, seed_helper: true do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }

  context :repo do
    let(:tree) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID) }

    it { expect(tree).to be_kind_of Array }
    it { expect(tree.empty?).to be_falsey }
    it { expect(tree.select(&:dir?).size).to eq(2) }
    it { expect(tree.select(&:file?).size).to eq(10) }
    it { expect(tree.select(&:submodule?).size).to eq(2) }

    describe '#dir?' do
      let(:dir) { tree.select(&:dir?).first }

      it { expect(dir).to be_kind_of Gitlab::Git::Tree }
      it { expect(dir.id).to eq('3c122d2b7830eca25235131070602575cf8b41a1') }
      it { expect(dir.commit_id).to eq(SeedRepo::Commit::ID) }
      it { expect(dir.name).to eq('encoding') }
      it { expect(dir.path).to eq('encoding') }
      it { expect(dir.flat_path).to eq('encoding') }
      it { expect(dir.mode).to eq('40000') }

      context :subdir do
        let(:subdir) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files').first }

        it { expect(subdir).to be_kind_of Gitlab::Git::Tree }
        it { expect(subdir.id).to eq('a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba') }
        it { expect(subdir.commit_id).to eq(SeedRepo::Commit::ID) }
        it { expect(subdir.name).to eq('html') }
        it { expect(subdir.path).to eq('files/html') }
        it { expect(subdir.flat_path).to eq('files/html') }
      end

      context :subdir_file do
        let(:subdir_file) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files/ruby').first }

        it { expect(subdir_file).to be_kind_of Gitlab::Git::Tree }
        it { expect(subdir_file.id).to eq('7e3e39ebb9b2bf433b4ad17313770fbe4051649c') }
        it { expect(subdir_file.commit_id).to eq(SeedRepo::Commit::ID) }
        it { expect(subdir_file.name).to eq('popen.rb') }
        it { expect(subdir_file.path).to eq('files/ruby/popen.rb') }
        it { expect(subdir_file.flat_path).to eq('files/ruby/popen.rb') }
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

  describe '#where' do
    shared_examples '#where' do
      it 'returns an empty array when called with an invalid ref' do
        expect(described_class.where(repository, 'foobar-does-not-exist')).to eq([])
      end
    end

    context 'with gitaly' do
      it_behaves_like '#where'
    end

    context 'without gitaly', :skip_gitaly_mock do
      it_behaves_like '#where'
    end
  end
end
