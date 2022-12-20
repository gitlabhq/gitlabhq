# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Tree do
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository.raw }

  shared_examples 'repo' do
    subject(:tree) { Gitlab::Git::Tree.where(repository, sha, path, recursive, skip_flat_paths, pagination_params) }

    let(:sha) { SeedRepo::Commit::ID }
    let(:path) { nil }
    let(:recursive) { false }
    let(:pagination_params) { nil }
    let(:skip_flat_paths) { false }

    let(:entries) { tree.first }
    let(:cursor) { tree.second }

    it { expect(entries).to be_kind_of Array }
    it { expect(entries.empty?).to be_falsey }
    it { expect(entries.count(&:dir?)).to eq(2) }
    it { expect(entries.count(&:file?)).to eq(10) }
    it { expect(entries.count(&:submodule?)).to eq(2) }
    it { expect(cursor&.next_cursor).to be_blank }

    context 'with an invalid ref' do
      let(:sha) { 'foobar-does-not-exist' }

      it { expect(entries).to eq([]) }
      it { expect(cursor).to be_nil }
    end

    context 'when path is provided' do
      let(:path) { 'files' }
      let(:recursive) { true }

      it 'returns a list of tree objects' do
        expect(entries.map(&:path)).to include('files/html',
                                               'files/markdown/ruby-style-guide.md')
        expect(entries.count).to be >= 10
        expect(entries).to all(be_a(Gitlab::Git::Tree))
      end
    end

    describe '#dir?' do
      let(:dir) { entries.find(&:dir?) }

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
        let(:path) { 'files' }
        let(:subdir) { entries.first }
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
        let(:path) { 'files/ruby' }
        let(:subdir_file) { entries.first }
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
        let(:path) { 'files/flat' }
        # rubocop: disable Rails/FindBy
        # This is not ActiveRecord where..first
        let(:subdir_file) { entries.first }
        # rubocop: enable Rails/FindBy
        let!(:sha) do
          repository.commit_files(
            user,
            branch_name: 'HEAD',
            message: "Create #{filename}",
            actions: [{
              action: :create,
              file_path: filename,
              contents: 'test'
            }]
          ).newrev
        end

        it { expect(subdir_file.flat_path).to eq('files/flat/path/correct') }

        context 'when skip_flat_paths is true' do
          let(:skip_flat_paths) { true }

          it { expect(subdir_file.flat_path).to be_blank }
        end
      end
    end

    describe '#file?' do
      let(:file) { entries.find(&:file?) }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { expect(file.id).to eq('dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82') }
      it { expect(file.commit_id).to eq(SeedRepo::Commit::ID) }
      it { expect(file.name).to eq('.gitignore') }
    end

    describe '#readme?' do
      let(:file) { entries.find(&:readme?) }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { expect(file.name).to eq('README.md') }
    end

    describe '#contributing?' do
      let(:file) { entries.find(&:contributing?) }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { expect(file.name).to eq('CONTRIBUTING.md') }
    end

    describe '#submodule?' do
      let(:submodule) { entries.find(&:submodule?) }

      it { expect(submodule).to be_kind_of Gitlab::Git::Tree }
      it { expect(submodule.id).to eq('79bceae69cb5750d6567b223597999bfa91cb3b9') }
      it { expect(submodule.commit_id).to eq('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
      it { expect(submodule.name).to eq('gitlab-shell') }
    end
  end

  describe '.where with Gitaly enabled' do
    it_behaves_like 'repo' do
      context 'with pagination parameters' do
        let(:pagination_params) { { limit: 3, page_token: nil } }

        it 'returns paginated list of tree objects' do
          expect(entries.count).to eq(3)
          expect(cursor.next_cursor).to be_present
        end
      end
    end
  end

  describe '.where with Rugged enabled', :enable_rugged do
    it 'calls out to the Rugged implementation' do
      allow_next_instance_of(Rugged) do |instance|
        allow(instance).to receive(:lookup).with(SeedRepo::Commit::ID)
      end

      described_class.where(repository, SeedRepo::Commit::ID, 'files', false, false)
    end

    it_behaves_like 'repo' do
      describe 'Pagination' do
        context 'with restrictive limit' do
          let(:pagination_params) { { limit: 3, page_token: nil } }

          it 'returns limited paginated list of tree objects' do
            expect(entries.count).to eq(3)
            expect(cursor.next_cursor).to be_present
          end
        end

        context 'when limit is equal to number of entries' do
          let(:entries_count) { entries.count }

          it 'returns all entries without a cursor' do
            result, cursor = Gitlab::Git::Tree.where(repository, sha, path, recursive, skip_flat_paths, { limit: entries_count, page_token: nil })

            expect(cursor).to be_nil
            expect(result.entries.count).to eq(entries_count)
          end
        end

        context 'when limit is 0' do
          let(:pagination_params) { { limit: 0, page_token: nil } }

          it 'returns empty result' do
            expect(entries).to eq([])
            expect(cursor).to be_nil
          end
        end

        context 'when limit is missing' do
          let(:pagination_params) { { limit: nil, page_token: nil } }

          it 'returns empty result' do
            expect(entries).to eq([])
            expect(cursor).to be_nil
          end
        end

        context 'when limit is negative' do
          let(:entries_count) { entries.count }

          it 'returns all entries' do
            result, cursor = Gitlab::Git::Tree.where(repository, sha, path, recursive, skip_flat_paths, { limit: -1, page_token: nil })

            expect(result.count).to eq(entries_count)
            expect(cursor).to be_nil
          end

          context 'when token is provided' do
            let(:pagination_params) { { limit: 1000, page_token: nil } }
            let(:token) { entries.second.id }

            it 'returns all entries after token' do
              result, cursor = Gitlab::Git::Tree.where(repository, sha, path, recursive, skip_flat_paths, { limit: -1, page_token: token })

              expect(result.count).to eq(entries.count - 2)
              expect(cursor).to be_nil
            end
          end
        end

        context 'when token does not exist' do
          let(:pagination_params) { { limit: 5, page_token: 'aabbccdd' } }

          it 'raises a command error' do
            expect { entries }.to raise_error(Gitlab::Git::CommandError, /could not find starting OID: aabbccdd/)
          end
        end

        context 'when limit is bigger than number of entries' do
          let(:pagination_params) { { limit: 1000, page_token: nil } }

          it 'returns only available entries' do
            expect(entries.count).to be < 20
            expect(cursor).to be_nil
          end
        end

        it 'returns all tree entries in specific order during cursor pagination' do
          collected_entries = []
          token = nil

          expected_entries = entries

          loop do
            result, cursor = Gitlab::Git::Tree.where(repository, sha, path, recursive, skip_flat_paths, { limit: 5, page_token: token })

            collected_entries += result.entries
            token = cursor&.next_cursor

            break if token.blank?
          end

          expect(collected_entries.map(&:path)).to match_array(expected_entries.map(&:path))

          expected_order = [
            collected_entries.select(&:dir?).map(&:path),
            collected_entries.select(&:file?).map(&:path),
            collected_entries.select(&:submodule?).map(&:path)
          ].flatten

          expect(collected_entries.map(&:path)).to eq(expected_order)
        end
      end
    end
  end
end
