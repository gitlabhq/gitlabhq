require 'spec_helper'

describe Gitlab::Ci::Build::Artifacts::Path do
  describe '#valid?' do
    context 'when path contains a zero character' do
      it 'is not valid' do
        expect(described_class.new("something/\255")).not_to be_valid
      end
    end

    context 'when path is not utf8 string' do
      it 'is not valid' do
        expect(described_class.new("something/\0")).not_to be_valid
      end
    end

    context 'when path is valid' do
      it 'is valid' do
        expect(described_class.new("some/file/path")).to be_valid
      end
    end
  end

  describe '#directory?' do
    context 'when path ends with a directory indicator' do
      it 'is a directory' do
        expect(described_class.new("some/file/dir/")).to be_directory
      end
    end

    context 'when path does not end with a directory indicator' do
      it 'is not a directory' do
        expect(described_class.new("some/file")).not_to be_directory
      end
    end
  end

  describe '#name' do
    it 'returns a base name' do
      expect(described_class.new("some/file").name).to eq 'file'
    end
  end

  describe '#nodes' do
    it 'returns number of path nodes' do
      expect(described_class.new("some/dir/file").nodes).to eq 2
    end
  end

  describe '#to_s' do
    context 'when path is valid' do
      it 'returns a string representation of a path' do
        expect(described_class.new('some/path').to_s).to eq 'some/path'
      end
    end

    context 'when path is invalid' do
      it 'raises an error' do
        expect { described_class.new("invalid/\0").to_s }
          .to raise_error ArgumentError
      end
    end
  end
end
