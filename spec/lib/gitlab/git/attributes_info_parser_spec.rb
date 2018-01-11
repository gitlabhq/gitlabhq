require 'spec_helper'

describe Gitlab::Git::AttributesInfoParser, seed_helper: true do
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

  describe '#patterns' do
    it 'does not parse anything when the attributes file does not exist' do
      expect(File).to receive(:exist?)
        .with(File.join(path, 'info/attributes'))
        .and_return(false)

      expect(subject.patterns).to eq({})
    end
  end

  describe '#each_line' do
    it 'iterates over every line in the attributes file' do
      args = [String] * 14 # the number of lines in the file

      expect { |b| subject.each_line(&b) }.to yield_successive_args(*args)
    end

    it 'does not yield when the attributes file does not exist' do
      expect(File).to receive(:exist?)
        .with(File.join(path, 'info/attributes'))
        .and_return(false)

      expect { |b| subject.each_line(&b) }.not_to yield_control
    end

    it 'does not yield when the attributes file has an unsupported encoding' do
      path = File.join(SEED_STORAGE_PATH, 'with-invalid-git-attributes.git')
      attrs = described_class.new(path)

      expect { |b| attrs.each_line(&b) }.not_to yield_control
    end
  end
end
