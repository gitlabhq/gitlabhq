# frozen_string_literal: true

require 'spec_helper'

describe UploadedFile do
  let(:temp_dir) { Dir.tmpdir }
  let(:temp_file) { Tempfile.new(%w[test test], temp_dir) }

  before do
    FileUtils.touch(temp_file)
  end

  after do
    FileUtils.rm_f(temp_file)
  end

  describe ".from_params" do
    let(:upload_path) { nil }
    let(:file_path_override) { nil }

    after do
      FileUtils.rm_r(upload_path) if upload_path
    end

    subject do
      described_class.from_params(params, :file, upload_path, file_path_override)
    end

    context 'when valid file is specified' do
      context 'only local path is specified' do
        let(:params) do
          { 'file.path' => temp_file.path }
        end

        it { is_expected.not_to be_nil }

        it "generates filename from path" do
          expect(subject.original_filename).to eq(::File.basename(temp_file.path))
        end
      end

      context 'all parameters are specified' do
        RSpec.shared_context 'filepath override' do
          let(:temp_file_override) { Tempfile.new(%w[override override], temp_dir) }
          let(:file_path_override) { temp_file_override.path }

          before do
            FileUtils.touch(temp_file_override)
          end

          after do
            FileUtils.rm_f(temp_file_override)
          end
        end

        RSpec.shared_examples 'using the file path' do |filename:, content_type:, sha256:, path_suffix:|
          it 'sets properly the attributes' do
            expect(subject.original_filename).to eq(filename)
            expect(subject.content_type).to eq(content_type)
            expect(subject.sha256).to eq(sha256)
            expect(subject.remote_id).to be_nil
            expect(subject.path).to end_with(path_suffix)
          end

          it 'handles a blank path' do
            params['file.path'] = ''

            # Not a real file, so can't determine size itself
            params['file.size'] = 1.byte

            expect { described_class.from_params(params, :file, upload_path) }
              .not_to raise_error
          end
        end

        RSpec.shared_examples 'using the remote id' do |filename:, content_type:, sha256:, size:, remote_id:|
          it 'sets properly the attributes' do
            expect(subject.original_filename).to eq(filename)
            expect(subject.content_type).to eq('application/octet-stream')
            expect(subject.sha256).to eq('sha256')
            expect(subject.path).to be_nil
            expect(subject.size).to eq(123456)
            expect(subject.remote_id).to eq('1234567890')
          end
        end

        context 'with a filepath' do
          let(:params) do
            { 'file.path' => temp_file.path,
              'file.name' => 'dir/my file&.txt',
              'file.type' => 'my/type',
              'file.sha256' => 'sha256' }
          end

          it { is_expected.not_to be_nil }

          it_behaves_like 'using the file path',
                          filename: 'my_file_.txt',
                          content_type: 'my/type',
                          sha256: 'sha256',
                          path_suffix: 'test'
        end

        context 'with a filepath override' do
          include_context 'filepath override'

          let(:params) do
            { 'file.path' => temp_file.path,
              'file.name' => 'dir/my file&.txt',
              'file.type' => 'my/type',
              'file.sha256' => 'sha256' }
          end

          it { is_expected.not_to be_nil }

          it_behaves_like 'using the file path',
                          filename: 'my_file_.txt',
                          content_type: 'my/type',
                          sha256: 'sha256',
                          path_suffix: 'override'
        end

        context 'with a remote id' do
          let(:params) do
            {
              'file.name' => 'dir/my file&.txt',
              'file.sha256' => 'sha256',
              'file.remote_url' => 'http://localhost/file',
              'file.remote_id' => '1234567890',
              'file.etag' => 'etag1234567890',
              'file.size' => '123456'
            }
          end

          it { is_expected.not_to be_nil }

          it_behaves_like 'using the remote id',
                          filename: 'my_file_.txt',
                          content_type: 'application/octet-stream',
                          sha256: 'sha256',
                          size: 123456,
                          remote_id: '1234567890'
        end

        context 'with a path and a remote id' do
          let(:params) do
            {
              'file.path' => temp_file.path,
              'file.name' => 'dir/my file&.txt',
              'file.sha256' => 'sha256',
              'file.remote_url' => 'http://localhost/file',
              'file.remote_id' => '1234567890',
              'file.etag' => 'etag1234567890',
              'file.size' => '123456'
            }
          end

          it { is_expected.not_to be_nil }

          it_behaves_like 'using the remote id',
                          filename: 'my_file_.txt',
                          content_type: 'application/octet-stream',
                          sha256: 'sha256',
                          size: 123456,
                          remote_id: '1234567890'
        end

        context 'with a path override and a remote id' do
          include_context 'filepath override'

          let(:params) do
            {
              'file.name' => 'dir/my file&.txt',
              'file.sha256' => 'sha256',
              'file.remote_url' => 'http://localhost/file',
              'file.remote_id' => '1234567890',
              'file.etag' => 'etag1234567890',
              'file.size' => '123456'
            }
          end

          it { is_expected.not_to be_nil }

          it_behaves_like 'using the remote id',
                          filename: 'my_file_.txt',
                          content_type: 'application/octet-stream',
                          sha256: 'sha256',
                          size: 123456,
                          remote_id: '1234567890'
        end
      end
    end

    context 'when no params are specified' do
      let(:params) do
        {}
      end

      it "does not return an object" do
        is_expected.to be_nil
      end
    end

    context 'when verifying allowed paths' do
      let(:params) do
        { 'file.path' => temp_file.path }
      end

      context 'when file is stored in system temporary folder' do
        let(:temp_dir) { Dir.tmpdir }

        it "succeeds" do
          is_expected.not_to be_nil
        end
      end

      context 'when file is stored in user provided upload path' do
        let(:upload_path) { Dir.mktmpdir }
        let(:temp_dir) { upload_path }

        it "succeeds" do
          is_expected.not_to be_nil
        end
      end

      context 'when file is stored outside of user provided upload path' do
        let!(:generated_dir) { Dir.mktmpdir }
        let!(:temp_dir) { Dir.mktmpdir }

        before do
          # We overwrite default temporary path
          allow(Dir).to receive(:tmpdir).and_return(generated_dir)
        end

        it "raises an error" do
          expect { subject }.to raise_error(UploadedFile::InvalidPathError, /insecure path used/)
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
  end

  describe '#sanitize_filename' do
    it { expect(described_class.new(temp_file.path).sanitize_filename('spaced name')).to eq('spaced_name') }
    it { expect(described_class.new(temp_file.path).sanitize_filename('#$%^&')).to eq('_____') }
    it { expect(described_class.new(temp_file.path).sanitize_filename('..')).to eq('_..') }
    it { expect(described_class.new(temp_file.path).sanitize_filename('')).to eq('unnamed') }
  end
end
