# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::FileInfo, feature_category: :shared do
  let(:tmpdir) { Dir.mktmpdir }
  let(:file_path) { "#{tmpdir}/test.txt" }

  before do
    FileUtils.touch(file_path)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '.linked?' do
    it 'raises an error when file does not exist' do
      expect { subject.linked?("#{tmpdir}/foo") }.to raise_error(Errno::ENOENT)
    end

    shared_examples 'identifies a linked file' do
      it 'returns false when file or dir is not a link' do
        expect(subject.linked?(tmpdir)).to eq(false)
        expect(subject.linked?(file)).to eq(false)
      end

      it 'returns true when file or dir is symlinked' do
        FileUtils.symlink(tmpdir, "#{tmpdir}/symlinked_dir")
        FileUtils.symlink(file_path, "#{tmpdir}/symlinked_file.txt")

        expect(subject.linked?("#{tmpdir}/symlinked_dir")).to eq(true)
        expect(subject.linked?("#{tmpdir}/symlinked_file.txt")).to eq(true)
      end

      it 'returns true when file has more than one hard link' do
        FileUtils.link(file_path, "#{tmpdir}/hardlinked_file.txt")

        expect(subject.linked?(file)).to eq(true)
        expect(subject.linked?("#{tmpdir}/hardlinked_file.txt")).to eq(true)
      end
    end

    context 'when file is a File::Stat' do
      let(:file) { File.lstat(file_path) }

      it_behaves_like 'identifies a linked file'
    end

    context 'when file is path' do
      let(:file) { file_path }

      it_behaves_like 'identifies a linked file'
    end
  end

  describe '.shares_hard_link?' do
    it 'raises an error when file does not exist' do
      expect { subject.shares_hard_link?("#{tmpdir}/foo") }.to raise_error(Errno::ENOENT)
    end

    shared_examples 'identifies a file that shares a hard link' do
      it 'returns false when file or dir does not share hard links' do
        expect(subject.shares_hard_link?(tmpdir)).to eq(false)
        expect(subject.shares_hard_link?(file)).to eq(false)
      end

      it 'returns true when file has more than one hard link' do
        FileUtils.link(file_path, "#{tmpdir}/hardlinked_file.txt")

        expect(subject.shares_hard_link?(file)).to eq(true)
        expect(subject.shares_hard_link?("#{tmpdir}/hardlinked_file.txt")).to eq(true)
      end
    end

    context 'when file is a File::Stat' do
      let(:file) { File.lstat(file_path) }

      it_behaves_like 'identifies a file that shares a hard link'
    end

    context 'when file is path' do
      let(:file) { file_path }

      it_behaves_like 'identifies a file that shares a hard link'
    end
  end
end
