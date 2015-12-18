require 'spec_helper'

describe Gitlab::StringPath do
  let(:universe) do
    ['path/dir_1/',
     'path/dir_1/file_1',
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
  end
end
