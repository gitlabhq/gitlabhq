# encoding: utf-8

require "spec_helper"

describe Gitlab::Git::Blob, seed_helper: true do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }

  describe 'initialize' do
    let(:blob) { Gitlab::Git::Blob.new(name: 'test') }

    it 'handles nil data' do
      expect(blob.name).to eq('test')
      expect(blob.size).to eq(nil)
      expect(blob.loaded_size).to eq(nil)
    end
  end

  shared_examples 'finding blobs' do
    context 'nil path' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, nil) }

      it { expect(blob).to eq(nil) }
    end

    context 'blank path' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, '') }

      it { expect(blob).to eq(nil) }
    end

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
      let(:stub_limit) { 1000 }

      before do
        stub_const('Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE', stub_limit)
      end

      it { expect(blob.size).to eq(blob_size) }
      it { expect(blob.data.length).to eq(stub_limit) }

      it 'check that this test is sane' do
        # It only makes sense to test limiting if the blob is larger than the limit.
        expect(blob.size).to be > Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE
      end

      it 'can load all data' do
        blob.load_all_data!(repository)
        expect(blob.data.length).to eq(blob_size)
      end

      it 'marks the blob as binary' do
        expect(Gitlab::Git::Blob).to receive(:new)
          .with(hash_including(binary: true))
          .and_call_original

        expect(blob).to be_binary
      end
    end
  end

  describe '.find' do
    context 'when project_raw_show Gitaly feature is enabled' do
      it_behaves_like 'finding blobs'
    end

    context 'when project_raw_show Gitaly feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'finding blobs'
    end
  end

  shared_examples 'finding blobs by ID' do
    let(:raw_blob) { Gitlab::Git::Blob.raw(repository, SeedRepo::RubyBlob::ID) }
    let(:bad_blob) { Gitlab::Git::Blob.raw(repository, SeedRepo::BigCommit::ID) }

    it { expect(raw_blob.id).to eq(SeedRepo::RubyBlob::ID) }
    it { expect(raw_blob.data[0..10]).to eq("require \'fi") }
    it { expect(raw_blob.size).to eq(669) }
    it { expect(raw_blob.truncated?).to be_falsey }
    it { expect(bad_blob).to be_nil }

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

    context 'when sha references a tree' do
      it 'returns nil' do
        tree = repository.rugged.rev_parse('master^{tree}')

        blob = Gitlab::Git::Blob.raw(repository, tree.oid)

        expect(blob).to be_nil
      end
    end
  end

  describe '.raw' do
    context 'when the blob_raw Gitaly feature is enabled' do
      it_behaves_like 'finding blobs by ID'
    end

    context 'when the blob_raw Gitaly feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'finding blobs by ID'
    end
  end

  describe '.batch' do
    let(:blob_references) do
      [
        [SeedRepo::Commit::ID, "files/ruby/popen.rb"],
        [SeedRepo::Commit::ID, 'six']
      ]
    end

    subject { described_class.batch(repository, blob_references) }

    it { expect(subject.size).to eq(blob_references.size) }

    context 'first blob' do
      let(:blob) { subject[0] }

      it { expect(blob.id).to eq(SeedRepo::RubyBlob::ID) }
      it { expect(blob.name).to eq(SeedRepo::RubyBlob::NAME) }
      it { expect(blob.path).to eq("files/ruby/popen.rb") }
      it { expect(blob.commit_id).to eq(SeedRepo::Commit::ID) }
      it { expect(blob.data[0..10]).to eq(SeedRepo::RubyBlob::CONTENT[0..10]) }
      it { expect(blob.size).to eq(669) }
      it { expect(blob.mode).to eq("100644") }
    end

    context 'second blob' do
      let(:blob) { subject[1] }

      it { expect(blob.id).to eq('409f37c4f05865e4fb208c771485f211a22c4c2d') }
      it { expect(blob.data).to eq('') }
      it 'does not mark the blob as binary' do
        expect(blob).not_to be_binary
      end
    end

    context 'limiting' do
      subject { described_class.batch(repository, blob_references, blob_size_limit: blob_size_limit) }

      context 'positive' do
        let(:blob_size_limit) { 10 }

        it { expect(subject.first.data.size).to eq(10) }
      end

      context 'zero' do
        let(:blob_size_limit) { 0 }

        it 'only loads the metadata' do
          expect(subject.first.size).not_to be(0)
          expect(subject.first.data).to eq('')
        end
      end

      context 'negative' do
        let(:blob_size_limit) { -1 }

        it 'ignores MAX_DATA_DISPLAY_SIZE' do
          stub_const('Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE', 100)

          expect(subject.first.data.size).to eq(669)
        end
      end
    end
  end

  describe '.batch_lfs_pointers' do
    let(:tree_object) { repository.rugged.rev_parse('master^{tree}') }

    let(:non_lfs_blob) do
      Gitlab::Git::Blob.find(
        repository,
        'master',
        'README.md'
      )
    end

    let(:lfs_blob) do
      Gitlab::Git::Blob.find(
        repository,
        '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
        'files/lfs/image.jpg'
      )
    end

    it 'returns a list of Gitlab::Git::Blob' do
      blobs = described_class.batch_lfs_pointers(repository, [lfs_blob.id])

      expect(blobs.count).to eq(1)
      expect(blobs).to all( be_a(Gitlab::Git::Blob) )
    end

    it 'silently ignores tree objects' do
      blobs = described_class.batch_lfs_pointers(repository, [tree_object.oid])

      expect(blobs).to eq([])
    end

    it 'silently ignores non lfs objects' do
      blobs = described_class.batch_lfs_pointers(repository, [non_lfs_blob.id])

      expect(blobs).to eq([])
    end

    it 'avoids loading large blobs into memory' do
      expect(repository).not_to receive(:lookup)

      described_class.batch_lfs_pointers(repository, [non_lfs_blob.id])
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

  describe 'lfs_pointers' do
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
      it { expect(blob.lfs_size).to eq(19548) }
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
        it { expect(blob.lfs_size).to eq(1575078) }
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
