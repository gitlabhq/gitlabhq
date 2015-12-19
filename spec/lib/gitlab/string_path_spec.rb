require 'spec_helper'

describe Gitlab::StringPath do
  let(:universe) do
    ['path/',
     'path/dir_1/',
     'path/dir_1/file_1',
     'path/dir_1/file_b',
     'path/second_dir',
     'path/second_dir/dir_3/file_2',
     'path/second_dir/dir_3/file_3',
     'another_file',
     '/file/with/absolute_path']
  end

  describe '/file/with/absolute_path' do
    subject { described_class.new('/file/with/absolute_path', universe) }

    it { is_expected.to be_absolute } 
    it { is_expected.to_not be_relative }
    it { is_expected.to be_file }
    it { is_expected.to_not have_parent }

    describe '#basename' do
      subject { described_class.new('/file/with/absolute_path', universe).basename }

      it { is_expected.to eq 'absolute_path' }
    end
  end

  describe 'path/' do
    subject { described_class.new('path/', universe) }

    it { is_expected.to be_directory }
    it { is_expected.to be_relative }
    it { is_expected.to_not have_parent }
  end

  describe 'path/dir_1/' do
    subject { described_class.new('path/dir_1/', universe) }
    it { is_expected.to have_parent }

    describe '#files' do
      subject { described_class.new('path/dir_1/', universe).files }

      pending { is_expected.to all(be_an_instance_of described_class) }
      pending { is_expected.to be eq [Gitlab::StringPath.new('path/dir_1/file_1', universe),
                                      Gitlab::StringPath.new('path/dir_1/file_b', universe)] }
    end

    describe '#basename' do
      subject { described_class.new('path/dir_1/', universe).basename }
      it { is_expected.to eq 'dir_1/' }
    end

    describe '#parent' do
      subject { described_class.new('path/dir_1/', universe).parent }
      it { is_expected.to eq Gitlab::StringPath.new('path/', universe) }
    end
  end
end
