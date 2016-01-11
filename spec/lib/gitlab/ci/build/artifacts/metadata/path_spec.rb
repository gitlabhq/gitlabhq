require 'spec_helper'

describe Gitlab::Ci::Build::Artifacts::Metadata::Path do
  let(:universe) do
    ['path/',
     'path/dir_1/',
     'path/dir_1/file_1',
     'path/dir_1/file_b',
     'path/dir_1/subdir/',
     'path/dir_1/subdir/subfile',
     'path/second_dir',
     'path/second_dir/dir_3/file_2',
     'path/second_dir/dir_3/file_3',
     'another_directory/',
     'another_file',
     '/file/with/absolute_path']
  end

  def path(example)
    string_path(example.metadata[:path])
  end

  def string_path(string_path)
    described_class.new(string_path, universe)
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
      it { is_expected.to eq string_path('path/') }
    end

    describe '#children' do
      subject { |example| path(example).children }

      it { is_expected.to all(be_an_instance_of described_class) }
      it do
        is_expected.to contain_exactly string_path('path/dir_1/file_1'),
                                       string_path('path/dir_1/file_b'),
                                       string_path('path/dir_1/subdir/')
      end
    end

    describe '#files' do
      subject { |example| path(example).files }

      it { is_expected.to all(be_file) }
      it { is_expected.to all(be_an_instance_of described_class) }
      it do
        is_expected.to contain_exactly string_path('path/dir_1/file_1'),
                                       string_path('path/dir_1/file_b')
      end
    end

    describe '#directories' do
      subject { |example| path(example).directories }

      it { is_expected.to all(be_directory) }
      it { is_expected.to all(be_an_instance_of described_class) }
      it { is_expected.to contain_exactly string_path('path/dir_1/subdir/') }
    end

    describe '#directories!' do
      subject { |example| path(example).directories! }

      it { is_expected.to all(be_directory) }
      it { is_expected.to all(be_an_instance_of described_class) }
      it do
        is_expected.to contain_exactly string_path('path/dir_1/subdir/'),
                                       string_path('path/')
      end
    end
  end

  describe 'empty path', path: '' do
    subject { |example| path(example) }
    it { is_expected.to_not have_parent }

    describe '#children' do
      subject { |example| path(example).children }
      it { expect(subject.count).to eq 3 }
    end
  end

  describe '#nodes', path: 'test' do
    subject { |example| path(example).nodes }
    it { is_expected.to eq 1 }
  end

  describe '#nodes', path: 'test/' do
    subject { |example| path(example).nodes }
    it { is_expected.to eq 1 }
  end

  describe '#metadata' do
    let(:universe) do
      ['path/', 'path/file1', 'path/file2']
    end

    let(:metadata) do
      [{ name: '/path/' }, { name: '/path/file1' }, { name: '/path/file2' }]
    end

    subject do
      described_class.new('path/file1', universe, metadata).metadata[:name]
    end

    it { is_expected.to eq '/path/file1' }
  end

  describe '#exists?', path: 'another_file' do
    subject { |example| path(example).exists? }
    it { is_expected.to be true }
  end

  describe '#exists?', path: './non_existent/' do
    let(:universe) { ['./something'] }
    subject { |example| path(example).exists? }

    it { is_expected.to be false }
  end
end
