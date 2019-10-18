# frozen_string_literal: true

require 'spec_helper'

describe UploadedFile do
  let(:temp_dir) { Dir.tmpdir }
  let(:temp_file) { Tempfile.new("test", temp_dir) }

  before do
    FileUtils.touch(temp_file)
  end

  after do
    FileUtils.rm_f(temp_file)
  end

  describe ".from_params" do
    let(:upload_path) { nil }

    after do
      FileUtils.rm_r(upload_path) if upload_path
    end

    subject do
      described_class.from_params(params, :file, upload_path)
    end

    context 'when valid file is specified' do
      context 'only local path is specified' do
        let(:params) do
          { 'file.path' => temp_file.path }
        end

        it "succeeds" do
          is_expected.not_to be_nil
        end

        it "generates filename from path" do
          expect(subject.original_filename).to eq(::File.basename(temp_file.path))
        end
      end

      context 'all parameters are specified' do
        let(:params) do
          { 'file.path' => temp_file.path,
            'file.name' => 'dir/my file&.txt',
            'file.type' => 'my/type',
            'file.sha256' => 'sha256',
            'file.remote_id' => 'remote_id' }
        end

        it "succeeds" do
          is_expected.not_to be_nil
        end

        it "generates filename from path" do
          expect(subject.original_filename).to eq('my_file_.txt')
          expect(subject.content_type).to eq('my/type')
          expect(subject.sha256).to eq('sha256')
          expect(subject.remote_id).to eq('remote_id')
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
