# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploadedFile, feature_category: :package_registry do
  let(:temp_dir) { Dir.tmpdir }
  let(:temp_file) { Tempfile.new(%w[test test], temp_dir) }

  before do
    FileUtils.touch(temp_file)
  end

  after do
    FileUtils.rm_f(temp_file)
  end

  context 'from_params functions' do
    RSpec.shared_examples 'using the file path' do |filename:, content_type:, sha256:, path_suffix:, upload_duration:, sha1:, md5:|
      it { is_expected.not_to be_nil }

      it 'sets properly the attributes' do
        expect(subject.original_filename).to eq(filename)
        expect(subject.content_type).to eq(content_type)
        expect(subject.sha256).to eq(sha256)
        expect(subject.remote_id).to be_nil
        expect(subject.path).to end_with(path_suffix)
        expect(subject.upload_duration).to eq(upload_duration)
        expect(subject.sha1).to eq(sha1)
        expect(subject.md5).to eq(md5)
      end

      it 'handles a blank path' do
        params['path'] = ''

        # Not a real file, so can't determine size itself
        params['size'] = 1.byte

        expect { described_class.from_params(params, upload_path) }
          .not_to raise_error
      end
    end

    RSpec.shared_examples 'using the remote id' do |filename:, content_type:, sha256:, size:, remote_id:, upload_duration:, sha1:, md5:|
      it { is_expected.not_to be_nil }

      it 'sets properly the attributes' do
        expect(subject.original_filename).to eq(filename)
        expect(subject.content_type).to eq(content_type)
        expect(subject.sha256).to eq(sha256)
        expect(subject.path).to be_nil
        expect(subject.size).to eq(size)
        expect(subject.remote_id).to eq(remote_id)
        expect(subject.upload_duration).to eq(upload_duration)
        expect(subject.sha1).to eq(sha1)
        expect(subject.md5).to eq(md5)
      end
    end

    describe '.from_params' do
      let(:upload_path) { nil }

      after do
        FileUtils.rm_r(upload_path) if upload_path
      end

      subject do
        described_class.from_params(params, [upload_path, Dir.tmpdir])
      end

      context 'when valid file is specified' do
        context 'only local path is specified' do
          let(:params) { { 'path' => temp_file.path } }

          it { is_expected.not_to be_nil }

          it 'generates filename from path' do
            expect(subject.original_filename).to eq(::File.basename(temp_file.path))
          end
        end

        context 'all parameters are specified' do
          context 'with a filepath' do
            let(:params) do
              { 'path' => temp_file.path,
                'name' => 'dir/my file&.txt',
                'type' => 'my/type',
                'upload_duration' => '5.05',
                'sha256' => 'sha256',
                'sha1' => 'sha1',
                'md5' => 'md5' }
            end

            it_behaves_like 'using the file path',
              filename: 'my_file_.txt',
              content_type: 'my/type',
              sha256: 'sha256',
              path_suffix: 'test',
              upload_duration: 5.05,
              sha1: 'sha1',
              md5: 'md5'
          end

          context 'with a remote id' do
            let(:params) do
              {
                'name' => 'dir/my file&.txt',
                'sha256' => 'sha256',
                'remote_url' => 'http://localhost/file',
                'remote_id' => '1234567890',
                'etag' => 'etag1234567890',
                'upload_duration' => '5.05',
                'size' => '123456',
                'sha1' => 'sha1',
                'md5' => 'md5'
              }
            end

            it_behaves_like 'using the remote id',
              filename: 'my_file_.txt',
              content_type: 'application/octet-stream',
              sha256: 'sha256',
              size: 123456,
              remote_id: '1234567890',
              upload_duration: 5.05,
              sha1: 'sha1',
              md5: 'md5'
          end

          context 'with a path and a remote id' do
            let(:params) do
              {
                'path' => temp_file.path,
                'name' => 'dir/my file&.txt',
                'sha256' => 'sha256',
                'remote_url' => 'http://localhost/file',
                'remote_id' => '1234567890',
                'etag' => 'etag1234567890',
                'upload_duration' => '5.05',
                'size' => '123456',
                'sha1' => 'sha1',
                'md5' => 'md5'
              }
            end

            it_behaves_like 'using the remote id',
              filename: 'my_file_.txt',
              content_type: 'application/octet-stream',
              sha256: 'sha256',
              size: 123456,
              remote_id: '1234567890',
              upload_duration: 5.05,
              sha1: 'sha1',
              md5: 'md5'
          end
        end
      end

      context 'when no params are specified' do
        let(:params) { {} }

        it 'does not return an object' do
          is_expected.to be_nil
        end
      end

      context 'when verifying allowed paths' do
        let(:params) { { 'path' => temp_file.path } }

        context 'when file is stored in system temporary folder' do
          let(:temp_dir) { Dir.tmpdir }

          it { is_expected.not_to be_nil }
        end

        context 'when file is stored in user provided upload path' do
          let(:upload_path) { Dir.mktmpdir }
          let(:temp_dir) { upload_path }

          it { is_expected.not_to be_nil }
        end

        context 'when file is stored outside of user provided upload path' do
          let!(:generated_dir) { Dir.mktmpdir }
          let!(:temp_dir) { Dir.mktmpdir }

          before do
            # We overwrite default temporary path
            allow(Dir).to receive(:tmpdir).and_return(generated_dir)
          end

          it 'raises an error' do
            expect { subject }.to raise_error(UploadedFile::InvalidPathError, /insecure path used/)
          end
        end
      end
    end
  end

  describe '.initialize' do
    context 'when no size is provided' do
      it 'determine size from local path' do
        file = described_class.new(temp_file.path)

        expect(file.size).to eq(temp_file.size)
      end

      it 'raises an exception if is a remote file' do
        expect do
          described_class.new(nil, remote_id: 'id')
        end.to raise_error(UploadedFile::UnknownSizeError, 'Unable to determine file size')
      end
    end

    context 'when size is a number' do
      let_it_be(:size) { 1.gigabyte }

      it 'is overridden by the size of the local file' do
        file = described_class.new(temp_file.path, size: size)

        expect(file.size).to eq(temp_file.size)
      end

      it 'is respected if is a remote file' do
        file = described_class.new(nil, remote_id: 'id', size: size)

        expect(file.size).to eq(size)
      end
    end

    context 'when size is a string' do
      it 'is converted to a number' do
        file = described_class.new(nil, remote_id: 'id', size: '1')

        expect(file.size).to eq(1)
      end

      it 'raises an exception if does not represent a number' do
        expect do
          described_class.new(nil, remote_id: 'id', size: 'not a number')
        end.to raise_error(UploadedFile::UnknownSizeError, 'Unable to determine file size')
      end
    end

    context 'when upload_duration is not provided' do
      it 'sets upload_duration to zero' do
        file = described_class.new(temp_file.path)

        expect(file.upload_duration).to be_zero
      end
    end

    context 'when upload_duration is provided' do
      let(:file) { described_class.new(temp_file.path, upload_duration: duration) }

      context 'and upload_duration is a number' do
        let(:duration) { 5.505 }

        it 'sets the upload_duration' do
          expect(file.upload_duration).to eq(duration)
        end
      end

      context 'and upload_duration is a string' do
        context 'and represents a number' do
          let(:duration) { '5.505' }

          it 'converts upload_duration to a number' do
            expect(file.upload_duration).to eq(duration.to_f)
          end
        end

        context 'and does not represent a number' do
          let(:duration) { 'not a number' }

          it 'sets upload_duration to zero' do
            expect(file.upload_duration).to be_zero
          end
        end
      end
    end

    context 'when unknown keyword params are provided' do
      it 'raises an exception' do
        expect do
          described_class.new(temp_file.path, foo: 'param1', bar: 'param2')
        end.to raise_error(ArgumentError, 'unknown keyword(s): foo, bar')
      end
    end
  end

  describe '#sanitize_filename' do
    it { expect(described_class.new(temp_file.path).sanitize_filename('spaced name')).to eq('spaced_name') }
    it { expect(described_class.new(temp_file.path).sanitize_filename('#$%^&')).to eq('_____') }
    it { expect(described_class.new(temp_file.path).sanitize_filename('..')).to eq('_..') }
    it { expect(described_class.new(temp_file.path).sanitize_filename('')).to eq('unnamed') }
  end

  describe '#empty_size?' do
    it { expect(described_class.new(temp_file.path).empty_size?).to eq(true) }
  end
end
