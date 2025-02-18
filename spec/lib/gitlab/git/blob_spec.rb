# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Blob do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository.raw }

  describe 'initialize' do
    let(:blob) { described_class.new(name: 'test') }

    it 'handles nil data' do
      expect(described_class).not_to receive(:gitlab_blob_size)

      expect(blob.name).to eq('test')
      expect(blob.size).to eq(nil)
      expect(blob.loaded_size).to eq(nil)
    end

    it 'records blob size' do
      expect(described_class).to receive(:gitlab_blob_size).and_call_original

      described_class.new(name: 'test', size: 4, data: 'abcd')
    end

    context 'when untruncated' do
      it 'attempts to record gitlab_blob_truncated_false' do
        expect(described_class).to receive(:gitlab_blob_truncated_false).and_call_original

        described_class.new(name: 'test', size: 4, data: 'abcd')
      end
    end

    context 'when truncated' do
      it 'attempts to record gitlab_blob_truncated_true' do
        expect(described_class).to receive(:gitlab_blob_truncated_true).and_call_original

        described_class.new(name: 'test', size: 40, data: 'abcd')
      end
    end
  end

  shared_examples '.find' do
    context 'nil path' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], nil) }

      it { expect(blob).to eq(nil) }
    end

    context 'utf-8 branch' do
      let(:blob) { described_class.find(repository, 'Ääh-test-utf-8', "files/ruby/popen.rb") }

      it { expect(blob.id).to eq(SeedRepo::RubyBlob::ID) }
    end

    context 'blank path' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], '') }

      it { expect(blob).to eq(nil) }
    end

    context 'file in subdir' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], "files/ruby/popen.rb") }

      it { expect(blob.id).to eq(SeedRepo::RubyBlob::ID) }
      it { expect(blob.name).to eq(SeedRepo::RubyBlob::NAME) }
      it { expect(blob.path).to eq("files/ruby/popen.rb") }
      it { expect(blob.commit_id).to eq(TestEnv::BRANCH_SHA['master']) }
      it { expect(blob.data[0..10]).to eq(SeedRepo::RubyBlob::CONTENT[0..10]) }
      it { expect(blob.size).to eq(669) }
      it { expect(blob.mode).to eq("100644") }
    end

    context 'file in root' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], ".gitignore") }

      it { expect(blob.id).to eq("dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82") }
      it { expect(blob.name).to eq(".gitignore") }
      it { expect(blob.path).to eq(".gitignore") }
      it { expect(blob.commit_id).to eq(TestEnv::BRANCH_SHA['master']) }
      it { expect(blob.data[0..10]).to eq("*.rbc\n*.sas") }
      it { expect(blob.size).to eq(241) }
      it { expect(blob.mode).to eq("100644") }
      it { expect(blob).not_to be_binary_in_repo }
    end

    context 'file in root with leading slash' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], "/.gitignore") }

      it { expect(blob.id).to eq("dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82") }
      it { expect(blob.name).to eq(".gitignore") }
      it { expect(blob.path).to eq(".gitignore") }
      it { expect(blob.commit_id).to eq(TestEnv::BRANCH_SHA['master']) }
      it { expect(blob.data[0..10]).to eq("*.rbc\n*.sas") }
      it { expect(blob.size).to eq(241) }
      it { expect(blob.mode).to eq("100644") }
    end

    context 'non-exist file' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], "missing.rb") }

      it { expect(blob).to be_nil }
    end

    context 'six submodule' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], 'six') }

      it { expect(blob.id).to eq('409f37c4f05865e4fb208c771485f211a22c4c2d') }
      it { expect(blob.data).to eq('') }

      it 'does not get messed up by load_all_data!' do
        blob.load_all_data!(repository)
        expect(blob.data).to eq('')
      end

      it 'does not mark the blob as binary' do
        expect(blob).not_to be_binary_in_repo
      end
    end

    context 'large file' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], 'files/images/6049019_460s.jpg') }
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
        expect(described_class).to receive(:new)
          .with(hash_including(binary: true))
          .and_call_original

        expect(blob).to be_binary_in_repo
      end
    end
  end

  describe '.find with Gitaly enabled' do
    it_behaves_like '.find'
  end

  describe '.raw' do
    let(:raw_blob) { described_class.raw(repository, SeedRepo::RubyBlob::ID) }
    let(:bad_blob) { described_class.raw(repository, SeedRepo::BigCommit::ID) }

    it { expect(raw_blob.id).to eq(SeedRepo::RubyBlob::ID) }
    it { expect(raw_blob.data[0..10]).to eq("require \'fi") }
    it { expect(raw_blob.size).to eq(669) }
    it { expect(raw_blob.truncated?).to be_falsey }
    it { expect(bad_blob).to be_nil }
  end

  describe '.batch' do
    let(:blob_references) do
      [
        [TestEnv::BRANCH_SHA['master'], "files/ruby/popen.rb"],
        [TestEnv::BRANCH_SHA['master'], 'six']
      ]
    end

    subject { described_class.batch(repository, blob_references) }

    it { expect(subject.size).to eq(blob_references.size) }

    context 'first blob' do
      let(:blob) { subject[0] }

      it { expect(blob.id).to eq(SeedRepo::RubyBlob::ID) }
      it { expect(blob.name).to eq(SeedRepo::RubyBlob::NAME) }
      it { expect(blob.path).to eq("files/ruby/popen.rb") }
      it { expect(blob.commit_id).to eq(TestEnv::BRANCH_SHA['master']) }
      it { expect(blob.data[0..10]).to eq(SeedRepo::RubyBlob::CONTENT[0..10]) }
      it { expect(blob.size).to eq(669) }
      it { expect(blob.mode).to eq("100644") }
    end

    context 'second blob' do
      let(:blob) { subject[1] }

      it { expect(blob.id).to eq('409f37c4f05865e4fb208c771485f211a22c4c2d') }
      it { expect(blob.data).to eq('') }

      it 'does not mark the blob as binary' do
        expect(blob).not_to be_binary_in_repo
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

    context 'when large number of blobs requested' do
      let(:first_batch) do
        [
          [TestEnv::BRANCH_SHA['master'], 'files/ruby/popen.rb'],
          [TestEnv::BRANCH_SHA['master'], 'six']
        ]
      end

      let(:second_batch) do
        [
          [TestEnv::BRANCH_SHA['master'], 'some'],
          [TestEnv::BRANCH_SHA['master'], 'other']
        ]
      end

      let(:third_batch) do
        [
          [TestEnv::BRANCH_SHA['master'], 'files']
        ]
      end

      let(:blob_references) do
        first_batch + second_batch + third_batch
      end

      let(:client) { repository.gitaly_blob_client }
      let(:limit) { 10.megabytes }

      before do
        stub_const('Gitlab::Git::Blob::BATCH_SIZE', 2)
      end

      it 'fetches the blobs in batches' do
        expect(client).to receive(:get_blobs).with(first_batch, limit).ordered
        expect(client).to receive(:get_blobs).with(second_batch, limit).ordered
        expect(client).to receive(:get_blobs).with(third_batch, limit).ordered

        subject
      end
    end
  end

  describe '.batch_metadata' do
    let(:blob_references) do
      [
        [TestEnv::BRANCH_SHA['master'], "files/ruby/popen.rb"],
        [TestEnv::BRANCH_SHA['master'], 'six']
      ]
    end

    subject { described_class.batch_metadata(repository, blob_references) }

    it 'returns an empty data attribute' do
      first_blob, last_blob = subject

      expect(first_blob.data).to be_blank
      expect(first_blob.path).to eq("files/ruby/popen.rb")
      expect(last_blob.data).to be_blank
      expect(last_blob.path).to eq("six")
    end
  end

  describe '.batch_lfs_pointers' do
    let(:non_lfs_blob) do
      described_class.find(
        repository,
        'master',
        'README.md'
      )
    end

    let(:lfs_blob) do
      described_class.find(
        repository,
        TestEnv::BRANCH_SHA['master'],
        'files/lfs/lfs_object.iso'
      )
    end

    it 'returns a list of Gitlab::Git::Blob' do
      blobs = described_class.batch_lfs_pointers(repository, [lfs_blob.id])

      expect(blobs.count).to eq(1)
      expect(blobs).to all(be_a(described_class))
      expect(blobs).to be_an(Array)
    end

    it 'accepts blob IDs as a lazy enumerator' do
      blobs = described_class.batch_lfs_pointers(repository, [lfs_blob.id].lazy)

      expect(blobs.count).to eq(1)
      expect(blobs).to all(be_a(described_class))
    end

    it 'handles empty list of IDs gracefully' do
      blobs_1 = described_class.batch_lfs_pointers(repository, [].lazy)
      blobs_2 = described_class.batch_lfs_pointers(repository, [])

      expect(blobs_1).to eq([])
      expect(blobs_2).to eq([])
    end

    it 'silently ignores non lfs objects' do
      blobs = described_class.batch_lfs_pointers(repository, [non_lfs_blob.id])

      expect(blobs).to eq([])
    end

    it 'avoids loading large blobs into memory' do
      # This line could call `lookup` on `repository`, so do here before mocking.
      non_lfs_blob_id = non_lfs_blob.id

      expect(repository).not_to receive(:lookup)

      described_class.batch_lfs_pointers(repository, [non_lfs_blob_id])
    end
  end

  describe 'encoding', :aggregate_failures do
    context 'file with russian text' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], "encoding/russian.rb") }

      it 'has the correct blob attributes' do
        expect(blob.name).to eq("russian.rb")
        expect(blob.data.lines.first).to eq("Хороший файл")
        expect(blob.size).to eq(23)
        expect(blob.truncated?).to be_falsey
        # Run it twice since data is encoded after the first run
        expect(blob.truncated?).to be_falsey
        expect(blob.mode).to eq("100755")
      end
    end

    context 'file with Japanese text' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], "encoding/テスト.txt") }

      it 'has the correct blob attributes' do
        expect(blob.name).to eq("テスト.txt")
        expect(blob.data).to include("これはテスト")
        expect(blob.size).to eq(340)
        expect(blob.mode).to eq("100755")
        expect(blob.truncated?).to be_falsey
      end
    end

    context 'file with ISO-8859 text' do
      let(:blob) { described_class.find(repository, TestEnv::BRANCH_SHA['master'], "encoding/iso8859.txt") }

      it 'has the correct blob attributes' do
        expect(blob.name).to eq("iso8859.txt")
        expect(blob.loaded_size).to eq(3)
        expect(blob.size).to eq(3)
        expect(blob.mode).to eq("100644")
        expect(blob.truncated?).to be_falsey
      end
    end
  end

  describe 'mode' do
    context 'file regular' do
      let(:blob) do
        described_class.find(
          repository,
          TestEnv::BRANCH_SHA['master'],
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
        described_class.find(
          repository,
          TestEnv::BRANCH_SHA['with-executables'],
          'files/executables/ls'
        )
      end

      it { expect(blob.name).to eq('ls') }
      it { expect(blob.path).to eq('files/executables/ls') }
      it { expect(blob.size).to eq(23) }
      it { expect(blob.mode).to eq("100755") }
    end

    context 'file symlink to regular' do
      let(:blob) do
        described_class.find(
          repository,
          '88ce9520c07b7067f589b7f83a30b6250883115c',
          'symlink'
        )
      end

      it { expect(blob.name).to eq('symlink') }
      it { expect(blob.path).to eq('symlink') }
      it { expect(blob.size).to eq(6) }
      it { expect(blob.mode).to eq("120000") }
    end
  end

  describe 'lfs_pointers' do
    context 'file a valid lfs pointer' do
      let(:blob) do
        described_class.find(
          repository,
          TestEnv::BRANCH_SHA['png-lfs'],
          'files/images/emoji.png'
        )
      end

      it { expect(blob.lfs_pointer?).to eq(true) }
      it { expect(blob.lfs_oid).to eq("96f74c6fe7a2979eefb9ec74a5dfc6888fb25543cf99b77586b79afea1da6f97") }
      it { expect(blob.lfs_size).to eq(1219696) }
      it { expect(blob.id).to eq("ff0ab3afd1616ff78d0331865d922df103b64cf0") }
      it { expect(blob.name).to eq("emoji.png") }
      it { expect(blob.path).to eq("files/images/emoji.png") }
      it { expect(blob.size).to eq(132) }
      it { expect(blob.mode).to eq("100644") }
    end
  end

  describe '#load_all_data!' do
    let(:full_data) { 'abcd' }
    let(:blob) { described_class.new(name: 'test', size: 4, data: 'abc') }

    subject { blob.load_all_data!(repository) }

    it 'loads missing data' do
      expect(repository.gitaly_blob_client).to receive(:get_blob)
        .and_return(double(:response, data: full_data))

      subject

      expect(blob.data).to eq(full_data)
    end

    context 'with a fully loaded blob' do
      let(:blob) { described_class.new(name: 'test', size: 4, data: full_data) }

      it "doesn't perform any loading" do
        expect(repository.gitaly_blob_client).not_to receive(:get_blob)

        subject

        expect(blob.data).to eq(full_data)
      end
    end
  end

  describe '#raw' do
    let(:input_data) { (+"abcd \xE9efgh").force_encoding(Encoding::UTF_16BE) }
    let(:blob) { described_class.new(name: 'test', data: input_data.dup) }

    it 'loads unencoded raw blob' do
      expect(blob.raw).to eq(input_data)
    end
  end

  describe '#truncated?' do
    context 'when blob.size is nil' do
      let(:nil_size_blob) { described_class.new(name: 'test', data: 'abcd') }

      it 'returns false' do
        expect(nil_size_blob.truncated?).to be_falsey
      end
    end

    context 'when blob.data is missing' do
      let(:nil_data_blob) { described_class.new(name: 'test', size: 4) }

      it 'returns false' do
        expect(nil_data_blob.truncated?).to be_falsey
      end
    end

    context 'when the blob is truncated' do
      let(:truncated_blob) { described_class.new(name: 'test', size: 40, data: 'abcd') }

      it 'returns true' do
        expect(truncated_blob.truncated?).to be_truthy
      end
    end

    context 'when the blob is untruncated' do
      let(:untruncated_blob) { described_class.new(name: 'test', size: 4, data: 'abcd') }

      it 'returns false' do
        expect(untruncated_blob.truncated?).to be_falsey
      end
    end
  end

  describe 'metrics' do
    it 'defines :gitlab_blob_truncated_true counter' do
      expect(described_class).to respond_to(:gitlab_blob_truncated_true)
    end

    it 'defines :gitlab_blob_truncated_false counter' do
      expect(described_class).to respond_to(:gitlab_blob_truncated_false)
    end

    it 'defines :gitlab_blob_size histogram' do
      expect(described_class).to respond_to(:gitlab_blob_size)
    end
  end

  describe '#lines' do
    context 'when the encoding cannot be detected' do
      it 'successfully splits the data' do
        data = "test\nblob"
        blob = described_class.new(name: 'test', size: data.bytesize, data: data)
        expect(blob).to receive(:ruby_encoding) { nil }

        expect(blob.lines).to eq(data.split("\n"))
      end
    end
  end
end
