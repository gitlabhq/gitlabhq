require 'spec_helper'

describe Gitlab::StringPath do
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

    it { is_expected.to be_absolute } 
    it { is_expected.to_not be_relative }
    it { is_expected.to be_file }
    it { is_expected.to_not have_parent }
    it { is_expected.to_not have_descendants }

    describe '#basename' do
      subject { |example| path(example).basename }

      it { is_expected.to eq 'absolute_path' }
    end
  end

  describe 'path/', path: 'path/' do
    subject { |example| path(example) }

    it { is_expected.to be_directory }
    it { is_expected.to be_relative }
    it { is_expected.to have_parent }
  end

  describe 'path/dir_1/', path: 'path/dir_1/' do
    subject { |example| path(example) }

    it { is_expected.to have_parent }

    describe '#basename' do
      subject { |example| path(example).basename }

      it { is_expected.to eq 'dir_1/' }
    end

    describe '#parent' do
      subject { |example| path(example).parent }

      it { is_expected.to eq string_path('path/') }
    end

    describe '#descendants' do
      subject { |example| path(example).descendants }

      it { is_expected.to be_an_instance_of Array }
      it { is_expected.to all(be_an_instance_of described_class) }
      it { is_expected.to contain_exactly string_path('path/dir_1/file_1'),
                                          string_path('path/dir_1/file_b'),
                                          string_path('path/dir_1/subdir/'),
                                          string_path('path/dir_1/subdir/subfile') }
    end

    describe '#children' do
      subject { |example| path(example).children }

      it { is_expected.to all(be_an_instance_of described_class) }
      it { is_expected.to contain_exactly string_path('path/dir_1/file_1'),
                                          string_path('path/dir_1/file_b'),
                                          string_path('path/dir_1/subdir/') }
    end

    describe '#files' do
      subject { |example| path(example).files }

      it { is_expected.to all(be_file) }
      it { is_expected.to all(be_an_instance_of described_class) }
      it { is_expected.to contain_exactly string_path('path/dir_1/file_1'),
                                          string_path('path/dir_1/file_b') }
    end

    describe '#directories' do
      subject { |example| path(example).directories }

      it { is_expected.to all(be_directory) }
      it { is_expected.to all(be_an_instance_of described_class) }
      it { is_expected.to contain_exactly string_path('path/dir_1/subdir/') }
    end
  end

  describe './', path: './' do
    subject { |example| path(example) }

    it { is_expected.to_not have_parent }
    it { is_expected.to have_descendants }

    describe '#descendants' do
      subject { |example| path(example).descendants }

      it { expect(subject.count).to eq universe.count - 1 }
      it { is_expected.to_not include string_path('./') }
    end

    describe '#children' do
      subject { |example| path(example).children }

      it { expect(subject.count).to eq 3 }
    end
  end
end
