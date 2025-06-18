# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileDecompressionService, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:tmpdir) { Dir.mktmpdir }
  let_it_be(:ndjson_filename) { 'labels.ndjson' }
  let_it_be(:ndjson_filepath) { File.join(tmpdir, ndjson_filename) }
  let_it_be(:gz_filename) { "#{ndjson_filename}.gz" }
  let_it_be(:gz_filepath) { "spec/fixtures/bulk_imports/gz/#{gz_filename}" }
  let(:context) { instance_double(BulkImports::Pipeline::Context, override_file_size_limit?: false) }

  before do
    FileUtils.copy_file(gz_filepath, File.join(tmpdir, gz_filename))
    FileUtils.rm_rf(ndjson_filepath)
  end

  after(:all) do
    FileUtils.remove_entry(tmpdir)
  end

  subject { described_class.new(tmpdir: tmpdir, filename: gz_filename, context: context) }

  describe '#execute' do
    it 'decompresses specified file' do
      subject.execute

      expect(File.exist?(File.join(tmpdir, ndjson_filename))).to eq(true)
      expect(File.open(ndjson_filepath, &:readline)).to include('title', 'description')
    end

    context 'when the decompressed file size exceeds limit' do
      before do
        stub_application_setting(max_decompressed_archive_size: 1.0 / 1048576) # 1 B
      end

      it 'raises an error' do
        expect { subject.execute }.to raise_error(
          BulkImports::FileDecompressionService::ServiceError, 'File decompression error'
        )
      end

      context 'and file size limit is overridden' do
        before do
          allow(context).to receive(:override_file_size_limit?).and_return(true)
        end

        it 'does not raise an error' do
          expect { subject.execute }.not_to raise_error
        end

        it 'logs oversized file' do
          expect(::Import::Framework::Logger)
            .to receive(:info)
            .with(hash_including(
              message: 'Decompressed archive size limit reached',
              import_upload_decompressed_size: 259,
              decompressed_size_limit: 1
            ))

          subject.execute
        end
      end
    end

    context 'when dir is not in tmpdir' do
      subject { described_class.new(tmpdir: '/etc', filename: 'filename', context: context) }

      it 'raises an error' do
        expect { subject.execute }.to raise_error(StandardError, 'path /etc is not allowed')
      end
    end

    context 'when path is being traversed' do
      subject do
        described_class.new(tmpdir: File.join(Dir.mktmpdir, 'test', '..'), filename: 'filename', context: context)
      end

      it 'raises an error' do
        expect { subject.execute }.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError, 'Invalid path')
      end
    end

    shared_examples 'raises an error and removes the file' do |error_message:|
      specify do
        expect { subject.execute }
          .to raise_error(BulkImports::FileDecompressionService::ServiceError, error_message)
        expect(File).not_to exist(file)
      end
    end

    shared_context 'when compressed file' do
      let_it_be(:file) { File.join(tmpdir, 'file.gz') }

      subject { described_class.new(tmpdir: tmpdir, filename: 'file.gz', context: context) }

      before do
        FileUtils.send(link_method, File.join(tmpdir, gz_filename), file)
      end
    end

    shared_context 'when decompressed file' do
      let_it_be(:file) { File.join(tmpdir, 'file.txt') }

      subject { described_class.new(tmpdir: tmpdir, filename: gz_filename, context: context) }

      before do
        original_file = File.join(tmpdir, 'original_file.txt')
        FileUtils.touch(original_file)
        FileUtils.send(link_method, original_file, file)

        subject.instance_variable_set(:@decompressed_filepath, file)
      end
    end

    context 'when compressed file is a symlink' do
      let(:link_method) { :symlink }

      include_context 'when compressed file'

      include_examples 'raises an error and removes the file', error_message: 'File decompression error'
    end

    context 'when compressed file shares multiple hard links' do
      let(:link_method) { :link }

      include_context 'when compressed file'

      include_examples 'raises an error and removes the file', error_message: 'File decompression error'
    end

    context 'when decompressed file is a symlink' do
      let(:link_method) { :symlink }

      include_context 'when decompressed file'

      include_examples 'raises an error and removes the file', error_message: 'Invalid file'
    end

    context 'when decompressed file shares multiple hard links' do
      let(:link_method) { :link }

      include_context 'when decompressed file'

      include_examples 'raises an error and removes the file', error_message: 'Invalid file'
    end
  end
end
