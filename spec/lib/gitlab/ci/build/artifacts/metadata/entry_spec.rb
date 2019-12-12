# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Build::Artifacts::Metadata::Entry do
  let(:entries) do
    { 'path/' => {},
      'path/dir_1/' => {},
      'path/dir_1/file_1' => { size: 10 },
      'path/dir_1/file_b' => { size: 10 },
      'path/dir_1/subdir/' => {},
      'path/dir_1/subdir/subfile' => { size: 10 },
      'path/second_dir' => {},
      'path/second_dir/dir_3/file_2' => { size: 10 },
      'path/second_dir/dir_3/file_3' => { size: 10 },
      'another_directory/' => {},
      'another_file' => {},
      '/file/with/absolute_path' => {} }
  end

  def path(example)
    entry(example.metadata[:path])
  end

  def entry(path)
    described_class.new(path, entries)
  end

  describe '/file/with/absolute_path', path: '/file/with/absolute_path' do
    subject { |example| path(example) }

    it { is_expected.to be_file }
    it { is_expected.to have_parent }

    describe '#basename' do
      subject { |example| path(example).basename }

      it { is_expected.to eq 'absolute_path' }
    end
  end

  describe 'path/dir_1/', path: 'path/dir_1/' do
    subject { |example| path(example) }

    it { is_expected.to have_parent }
    it { is_expected.to be_directory }

    describe '#basename' do
      subject { |example| path(example).basename }

      it { is_expected.to eq 'dir_1/' }
    end

    describe '#name' do
      subject { |example| path(example).name }

      it { is_expected.to eq 'dir_1' }
    end

    describe '#parent' do
      subject { |example| path(example).parent }

      it { is_expected.to eq entry('path/') }
    end

    describe '#children' do
      subject { |example| path(example).children }

      it { is_expected.to all(be_an_instance_of described_class) }
      it do
        is_expected.to contain_exactly entry('path/dir_1/file_1'),
                                       entry('path/dir_1/file_b'),
                                       entry('path/dir_1/subdir/')
      end
    end

    describe '#files' do
      subject { |example| path(example).files }

      it { is_expected.to all(be_file) }
      it { is_expected.to all(be_an_instance_of described_class) }
      it do
        is_expected.to contain_exactly entry('path/dir_1/file_1'),
                                       entry('path/dir_1/file_b')
      end
    end

    describe '#directories' do
      context 'without options' do
        subject { |example| path(example).directories }

        it { is_expected.to all(be_directory) }
        it { is_expected.to all(be_an_instance_of described_class) }
        it { is_expected.to contain_exactly entry('path/dir_1/subdir/') }
      end

      context 'with option parent: true' do
        subject { |example| path(example).directories(parent: true) }

        it { is_expected.to all(be_directory) }
        it { is_expected.to all(be_an_instance_of described_class) }
        it do
          is_expected.to contain_exactly entry('path/dir_1/subdir/'),
                                         entry('path/')
        end
      end

      describe '#nodes' do
        subject { |example| path(example).nodes }

        it { is_expected.to eq 2 }
      end

      describe '#exists?' do
        subject { |example| path(example).exists? }

        it { is_expected.to be true }
      end

      describe '#empty?' do
        subject { |example| path(example).empty? }

        it { is_expected.to be false }
      end

      describe '#total_size' do
        subject { |example| path(example).total_size }

        it { is_expected.to eq(30) }
      end
    end
  end

  describe 'empty path', path: '' do
    subject { |example| path(example) }

    it { is_expected.not_to have_parent }

    describe '#children' do
      subject { |example| path(example).children }

      it { expect(subject.count).to eq 3 }
    end
  end

  describe 'path/dir_1/subdir/subfile', path: 'path/dir_1/subdir/subfile' do
    describe '#nodes' do
      subject { |example| path(example).nodes }

      it { is_expected.to eq 4 }
    end

    describe '#blob' do
      let(:file_entry) { |example| path(example) }

      subject { file_entry.blob }

      it 'returns a blob representing the entry data' do
        expect(subject).to be_a(Blob)
        expect(subject.path).to eq(file_entry.path)
        expect(subject.size).to eq(file_entry.metadata[:size])
      end
    end
  end

  describe 'non-existent/', path: 'non-existent/' do
    describe '#empty?' do
      subject { |example| path(example).empty? }

      it { is_expected.to be true }
    end

    describe '#exists?' do
      subject { |example| path(example).exists? }

      it { is_expected.to be false }
    end
  end

  describe 'another_directory/', path: 'another_directory/' do
    describe '#empty?' do
      subject { |example| path(example).empty? }

      it { is_expected.to be true }
    end
  end

  describe '#metadata' do
    let(:entries) do
      { 'path/' => { name: '/path/' },
        'path/file1' => { name: '/path/file1' },
        'path/file2' => { name: '/path/file2' } }
    end

    subject do
      described_class.new('path/file1', entries).metadata[:name]
    end

    it { is_expected.to eq '/path/file1' }
  end
end
