require 'spec_helper'

describe Gitlab::Git::InfoAttributes, seed_helper: true do
  let(:path) do
    File.join(SEED_STORAGE_PATH, 'with-git-attributes.git')
  end

  subject { described_class.new(path) }

  describe '#attributes' do
    context 'using a path with attributes' do
      it 'returns the attributes as a Hash' do
        expect(subject.attributes('test.txt')).to eq({ 'text' => true })
      end

      it 'returns an empty Hash for a defined path without attributes' do
        expect(subject.attributes('bla/bla.txt')).to eq({})
      end
    end
  end

  describe '#parser' do
    it 'parses a file with entries' do
      expect(subject.patterns).to be_an_instance_of(Hash)
      expect(subject.patterns["/*.txt"]).to eq({ 'text' => true })
    end

    it 'does not parse anything when the attributes file does not exist' do
      expect(File).to receive(:exist?)
        .with(File.join(path, 'info/attributes'))
        .and_return(false)

      expect(subject.patterns).to eq({})
    end

    it 'does not parse attributes files with unsupported encoding' do
      path = File.join(SEED_STORAGE_PATH, 'with-invalid-git-attributes.git')
      subject = described_class.new(path)

      expect(subject.patterns).to eq({})
    end
  end
end
