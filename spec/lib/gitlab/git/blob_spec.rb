# encoding: utf-8

require "spec_helper"

describe Gitlab::Git::Blob, seed_helper: true do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe :initialize do
    let(:blob) { Gitlab::Git::Blob.new(name: 'test') }

    it 'handles nil data' do
      expect(blob.name).to eq('test')
      expect(blob.size).to eq(nil)
      expect(blob.loaded_size).to eq(nil)
    end
  end

  describe :find do
    context 'file in subdir' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "files/ruby/popen.rb") }

      it { expect(blob.id).to eq(SeedRepo::RubyBlob::ID) }
      it { expect(blob.name).to eq(SeedRepo::RubyBlob::NAME) }
      it { expect(blob.path).to eq("files/ruby/popen.rb") }
      it { expect(blob.commit_id).to eq(SeedRepo::Commit::ID) }
      it { expect(blob.data[0..10]).to eq(SeedRepo::RubyBlob::CONTENT[0..10]) }
      it { expect(blob.size).to eq(669) }
      it { expect(blob.mode).to eq("100644") }
    end

    context 'file in root' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, ".gitignore") }

      it { expect(blob.id).to eq("dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82") }
      it { expect(blob.name).to eq(".gitignore") }
      it { expect(blob.path).to eq(".gitignore") }
      it { expect(blob.commit_id).to eq(SeedRepo::Commit::ID) }
      it { expect(blob.data[0..10]).to eq("*.rbc\n*.sas") }
      it { expect(blob.size).to eq(241) }
      it { expect(blob.mode).to eq("100644") }
      it { expect(blob).not_to be_binary }
    end

    context 'file in root with leading slash' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "/.gitignore") }

      it { expect(blob.id).to eq("dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82") }
      it { expect(blob.name).to eq(".gitignore") }
      it { expect(blob.path).to eq(".gitignore") }
      it { expect(blob.commit_id).to eq(SeedRepo::Commit::ID) }
      it { expect(blob.data[0..10]).to eq("*.rbc\n*.sas") }
      it { expect(blob.size).to eq(241) }
      it { expect(blob.mode).to eq("100644") }
    end

    context 'non-exist file' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "missing.rb") }

      it { expect(blob).to be_nil }
    end

    context 'six submodule' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, 'six') }

      it { expect(blob.id).to eq('409f37c4f05865e4fb208c771485f211a22c4c2d') }
      it { expect(blob.data).to eq('') }

      it 'does not get messed up by load_all_data!' do
        blob.load_all_data!(repository)
        expect(blob.data).to eq('')
      end

      it 'does not mark the blob as binary' do
        expect(blob).not_to be_binary
      end
    end

    context 'large file' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, 'files/images/6049019_460s.jpg') }
      let(:blob_size) { 111803 }

      it { expect(blob.size).to eq(blob_size) }
      it { expect(blob.data.length).to eq(blob_size) }

      it 'check that this test is sane' do
        expect(blob.size).to be <= Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE
      end

      it 'can load all data' do
        blob.load_all_data!(repository)
        expect(blob.data.length).to eq(blob_size)
      end

      it 'marks the blob as binary' do
        expect(Gitlab::Git::Blob).to receive(:new).
          with(hash_including(binary: true)).
          and_call_original

        expect(blob).to be_binary
      end
    end
  end

  describe :raw do
    let(:raw_blob) { Gitlab::Git::Blob.raw(repository, SeedRepo::RubyBlob::ID) }
    it { expect(raw_blob.id).to eq(SeedRepo::RubyBlob::ID) }
    it { expect(raw_blob.data[0..10]).to eq("require \'fi") }
    it { expect(raw_blob.size).to eq(669) }
    it { expect(raw_blob.truncated?).to be_falsey }

    context 'large file' do
      it 'limits the size of a large file' do
        blob_size = Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE + 1
        buffer = Array.new(blob_size, 0)
        rugged_blob = Rugged::Blob.from_buffer(repository.rugged, buffer.join(''))
        blob = Gitlab::Git::Blob.raw(repository, rugged_blob)

        expect(blob.size).to eq(blob_size)
        expect(blob.loaded_size).to eq(Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
        expect(blob.data.length).to eq(Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
        expect(blob.truncated?).to be_truthy

        blob.load_all_data!(repository)
        expect(blob.loaded_size).to eq(blob_size)
      end
    end
  end

  describe 'encoding' do
    context 'file with russian text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "encoding/russian.rb") }

      it { expect(blob.name).to eq("russian.rb") }
      it { expect(blob.data.lines.first).to eq("Хороший файл") }
      it { expect(blob.size).to eq(23) }
      it { expect(blob.truncated?).to be_falsey }
      # Run it twice since data is encoded after the first run
      it { expect(blob.truncated?).to be_falsey }
      it { expect(blob.mode).to eq("100755") }
    end

    context 'file with Chinese text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "encoding/テスト.txt") }

      it { expect(blob.name).to eq("テスト.txt") }
      it { expect(blob.data).to include("これはテスト") }
      it { expect(blob.size).to eq(340) }
      it { expect(blob.mode).to eq("100755") }
      it { expect(blob.truncated?).to be_falsey }
    end

    context 'file with ISO-8859 text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::LastCommit::ID, "encoding/iso8859.txt") }

      it { expect(blob.name).to eq("iso8859.txt") }
      it { expect(blob.loaded_size).to eq(4) }
      it { expect(blob.size).to eq(4) }
      it { expect(blob.mode).to eq("100644") }
      it { expect(blob.truncated?).to be_falsey }
    end
  end

  describe 'mode' do
    context 'file regular' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
          'files/ruby/regex.rb'
        )
      end

      it { expect(blob.name).to eq('regex.rb') }
      it { expect(blob.path).to eq('files/ruby/regex.rb') }
      it { expect(blob.size).to eq(1200) }
      it { expect(blob.mode).to eq("100644") }
    end

    context 'file binary' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
          'files/executables/ls'
        )
      end

      it { expect(blob.name).to eq('ls') }
      it { expect(blob.path).to eq('files/executables/ls') }
      it { expect(blob.size).to eq(110080) }
      it { expect(blob.mode).to eq("100755") }
    end

    context 'file symlink to regular' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
          'files/links/ruby-style-guide.md'
        )
      end

      it { expect(blob.name).to eq('ruby-style-guide.md') }
      it { expect(blob.path).to eq('files/links/ruby-style-guide.md') }
      it { expect(blob.size).to eq(31) }
      it { expect(blob.mode).to eq("120000") }
    end

    context 'file symlink to binary' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
          'files/links/touch'
        )
      end

      it { expect(blob.name).to eq('touch') }
      it { expect(blob.path).to eq('files/links/touch') }
      it { expect(blob.size).to eq(20) }
      it { expect(blob.mode).to eq("120000") }
    end
  end

  describe :commit do
    let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

    let(:commit_options) do
      {
         file: {
           content: 'Lorem ipsum...',
           path: 'documents/story.txt'
         },
         author: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         committer: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         commit: {
           message: 'Wow such commit',
           branch: 'fix-mode'
         }
      }
    end

    let(:commit_sha) { Gitlab::Git::Blob.commit(repository, commit_options) }
    let(:commit) { repository.lookup(commit_sha) }

    it 'should add file with commit' do
      # Commit message valid
      expect(commit.message).to eq('Wow such commit')

      tree = commit.tree.to_a.find { |tree| tree[:name] == 'documents' }

      # Directory was created
      expect(tree[:type]).to eq(:tree)

      # File was created
      expect(repository.lookup(tree[:oid]).first[:name]).to eq('story.txt')
    end

    describe "ref updating" do
      it 'creates a commit but does not udate a ref' do
        commit_opts = commit_options.tap{ |opts| opts[:commit][:update_ref] = false}
        commit_sha = Gitlab::Git::Blob.commit(repository, commit_opts)
        commit = repository.lookup(commit_sha)

        # Commit message valid
        expect(commit.message).to eq('Wow such commit')

        # Does not update any related ref
        expect(repository.lookup("fix-mode").oid).not_to eq(commit.oid)
        expect(repository.lookup("HEAD").oid).not_to eq(commit.oid)
      end
    end

    describe 'reject updates' do
      it 'should reject updates' do
        commit_options[:file][:update] = false
        commit_options[:file][:path] = 'files/executables/ls'

        expect{ commit_sha }.to raise_error('Filename already exists; update not allowed')
      end
    end

    describe 'file modes' do
      it 'should preserve file modes with commit' do
        commit_options[:file][:path] = 'files/executables/ls'

        entry = Gitlab::Git::Blob.find_entry_by_path(repository, commit.tree.oid, commit_options[:file][:path])
        expect(entry[:filemode]).to eq(0100755)
      end
    end
  end

  describe :rename do
    let(:repository) { Gitlab::Git::Repository.new(TEST_NORMAL_REPO_PATH) }
    let(:rename_options) do
      {
        file: {
          path: 'NEWCONTRIBUTING.md',
          previous_path: 'CONTRIBUTING.md',
          content: 'Lorem ipsum...',
          update: true
        },
        author: {
          email: 'user@example.com',
          name: 'Test User',
          time: Time.now
        },
        committer: {
          email: 'user@example.com',
          name: 'Test User',
          time: Time.now
        },
        commit: {
          message: 'Rename readme',
          branch: 'master'
        }
      }
    end

    let(:rename_options2) do
      {
         file: {
           content: 'Lorem ipsum...',
           path: 'bin/new_executable',
           previous_path: 'bin/executable',
         },
         author: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         committer: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         commit: {
           message: 'Updates toberenamed.txt',
           branch: 'master',
           update_ref: false
         }
      }
    end

    it 'maintains file permissions when renaming' do
      mode = 0o100755

      Gitlab::Git::Blob.rename(repository, rename_options2)

      expect(repository.rugged.index.get(rename_options2[:file][:path])[:mode]).to eq(mode)
    end

    it 'renames the file with commit and not change file permissions' do
      ref = rename_options[:commit][:branch]

      expect(repository.rugged.index.get('CONTRIBUTING.md')).not_to be_nil
      expect { Gitlab::Git::Blob.rename(repository, rename_options) }.to change { repository.commit_count(ref) }.by(1)

      expect(repository.rugged.index.get('CONTRIBUTING.md')).to be_nil
      expect(repository.rugged.index.get('NEWCONTRIBUTING.md')).not_to be_nil
    end
  end

  describe :remove do
    let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

    let(:commit_options) do
      {
         file: {
           path: 'README.md'
         },
         author: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         committer: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         commit: {
           message: 'Remove readme',
           branch: 'feature'
         }
      }
    end

    let(:commit_sha) { Gitlab::Git::Blob.remove(repository, commit_options) }
    let(:commit) { repository.lookup(commit_sha) }
    let(:blob) { Gitlab::Git::Blob.find(repository, commit_sha, "README.md") }

    it 'should remove file with commit' do
      # Commit message valid
      expect(commit.message).to eq('Remove readme')

      # File was removed
      expect(blob).to be_nil
    end
  end

  describe :lfs_pointers do
    context 'file a valid lfs pointer' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
          'files/lfs/image.jpg'
        )
      end

      it { expect(blob.lfs_pointer?).to eq(true) }
      it { expect(blob.lfs_oid).to eq("4206f951d2691c78aac4c0ce9f2b23580b2c92cdcc4336e1028742c0274938e0") }
      it { expect(blob.lfs_size).to eq("19548") }
      it { expect(blob.id).to eq("f4d76af13003d1106be7ac8c5a2a3d37ddf32c2a") }
      it { expect(blob.name).to eq("image.jpg") }
      it { expect(blob.path).to eq("files/lfs/image.jpg") }
      it { expect(blob.size).to eq(130) }
      it { expect(blob.mode).to eq("100644") }
    end

    describe 'file an invalid lfs pointer' do
      context 'with correct version header but incorrect size and oid' do
        let(:blob) do
          Gitlab::Git::Blob.find(
            repository,
            '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
            'files/lfs/archive-invalid.tar'
          )
        end

        it { expect(blob.lfs_pointer?).to eq(false) }
        it { expect(blob.lfs_oid).to eq(nil) }
        it { expect(blob.lfs_size).to eq(nil) }
        it { expect(blob.id).to eq("f8a898db217a5a85ed8b3d25b34c1df1d1094c46") }
        it { expect(blob.name).to eq("archive-invalid.tar") }
        it { expect(blob.path).to eq("files/lfs/archive-invalid.tar") }
        it { expect(blob.size).to eq(43) }
        it { expect(blob.mode).to eq("100644") }
      end

      context 'with correct version header and size but incorrect size and oid' do
        let(:blob) do
          Gitlab::Git::Blob.find(
            repository,
            '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
            'files/lfs/picture-invalid.png'
          )
        end

        it { expect(blob.lfs_pointer?).to eq(false) }
        it { expect(blob.lfs_oid).to eq(nil) }
        it { expect(blob.lfs_size).to eq("1575078") }
        it { expect(blob.id).to eq("5ae35296e1f95c1ef9feda1241477ed29a448572") }
        it { expect(blob.name).to eq("picture-invalid.png") }
        it { expect(blob.path).to eq("files/lfs/picture-invalid.png") }
        it { expect(blob.size).to eq(57) }
        it { expect(blob.mode).to eq("100644") }
      end

      context 'with correct version header and size but invalid size and oid' do
        let(:blob) do
          Gitlab::Git::Blob.find(
            repository,
            '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
            'files/lfs/file-invalid.zip'
          )
        end

        it { expect(blob.lfs_pointer?).to eq(false) }
        it { expect(blob.lfs_oid).to eq(nil) }
        it { expect(blob.lfs_size).to eq(nil) }
        it { expect(blob.id).to eq("d831981bd876732b85a1bcc6cc01210c9f36248f") }
        it { expect(blob.name).to eq("file-invalid.zip") }
        it { expect(blob.path).to eq("files/lfs/file-invalid.zip") }
        it { expect(blob.size).to eq(60) }
        it { expect(blob.mode).to eq("100644") }
      end
    end
  end
end
