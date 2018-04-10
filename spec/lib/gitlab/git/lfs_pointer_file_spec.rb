require 'spec_helper'

describe Gitlab::Git::LfsPointerFile do
  let(:data) { "1234\n" }

  subject { described_class.new(data) }

  describe '#size' do
    it 'counts the bytes' do
      expect(subject.size).to eq 5
    end

    it 'handles non ascii data' do
      expect(described_class.new("ääää").size).to eq 8
    end
  end

  describe '#sha256' do
    it 'hashes the content correctly' do
      expect(subject.sha256).to eq 'a883dafc480d466ee04e0d6da986bd78eb1fdd2178d04693723da3a8f95d42f4'
    end
  end

  describe '#pointer' do
    it 'starts with the LFS version' do
      expect(subject.pointer).to start_with('version https://git-lfs.github.com/spec/v1')
    end

    it 'includes sha256' do
      expect(subject.pointer).to match(/^oid sha256:[0-9a-fA-F]{64}/)
    end

    it 'ends with the size' do
      expect(subject.pointer).to end_with("\nsize 5\n")
    end
  end
end
