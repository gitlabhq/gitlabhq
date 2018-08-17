require 'fast_spec_helper'

describe Gitlab::Ci::Config::Extendable::Entry do
  describe '.new' do
    context 'when entry key is not included in the context hash' do
      it 'raises error' do
        expect { described_class.new(:test, something: 'something') }
          .to raise_error StandardError, 'Invalid entry key!'
      end
    end
  end

  describe '#value' do
    it 'reads a hash value from the context' do
      entry = described_class.new(:test, test: 'something')

      expect(entry.value).to eq 'something'
    end
  end

  describe '#extensible?' do
    context 'when entry has inheritance defined' do
      it 'is extensible' do
        entry = described_class.new(:test, test: { extends: 'something' })

        expect(entry).to be_extensible
      end
    end

    context 'when entry does not have inheritance specified' do
      it 'is not extensible' do
        entry = described_class.new(:test, test: { script: 'something' })

        expect(entry).not_to be_extensible
      end
    end

    context 'when entry value is not a hash' do
      it 'is not extensible' do
        entry = described_class.new(:test, test: 'something')

        expect(entry).not_to be_extensible
      end
    end
  end

  describe '#extends_key' do
    context 'when entry is extensible' do
      it 'returns symbolized extends key value' do
        entry = described_class.new(:test, test: { extends: 'something' })

        expect(entry.extends_key).to eq :something
      end
    end

    context 'when entry is not extensible' do
      it 'returns nil' do
        entry = described_class.new(:test, test: 'something')

        expect(entry.extends_key).to be_nil
      end
    end
  end

  describe '#path' do
    it 'returns inheritance chain path' do
      parent = described_class.new(:test, test: { extends: 'something' })
      child = described_class.new(:job, { job: { script: 'something' } }, parent)

      expect(child.path).to eq [:test, :job]
    end
  end

  describe '#base_hash!' do
    subject { described_class.new(:test, hash) }

    context 'when base hash is not extensible' do
      let(:hash) do
        {
          template: { script: 'rspec' },
          test: { extends: 'template' }
        }
      end

      it 'returns unchanged base hash' do
        expect(subject.base_hash!).to eq(script: 'rspec')
      end
    end

    context 'when base hash is extensible too' do
      let(:hash) do
        {
          first: { script: 'rspec' },
          second: { extends: 'first' },
          test: { extends: 'second' }
        }
      end

      it 'extends the base hash first' do
        expect(subject.base_hash!).to eq(extends: 'first', script: 'rspec')
      end

      it 'mutates original context' do
        subject.base_hash!

        expect(hash.fetch(:second)).to eq(extends: 'first', script: 'rspec')
      end
    end
  end

  describe '#extend!' do
    subject { described_class.new(:test, hash) }

    context 'when extending a non-hash value' do
      let(:hash) do
        {
          first: 'my value',
          test: { extends: 'first' }
        }
      end

      it 'raises an error' do
        expect { subject.extend! }
          .to raise_error(StandardError, /Invalid base hash/)
      end
    end

    context 'when extending unknown key' do
      let(:hash) do
        { test: { extends: 'something' } }
      end

      it 'raises an error' do
        expect { subject.extend! }
          .to raise_error(StandardError, /Unknown extends key/)
      end
    end

    context 'when extending a hash correctly' do
      let(:hash) do
        {
          first: { script: 'my value' },
          second: { extends: 'first' },
          test: { extends: 'second' }
        }
      end

      let(:result) do
        {
          first: { script: 'my value' },
          second: { extends: 'first', script: 'my value' },
          test: { extends: 'second', script: 'my value' }
        }
      end

      it 'returns extended part of the hash' do
        expect(subject.extend!).to eq result[:test]
      end

      it 'mutates original context' do
        subject.extend!

        expect(hash).to eq result
      end
    end

    context 'when hash is not extensible' do
      let(:hash) do
        {
          first: { script: 'my value' },
          second: { extends: 'first' },
          test: { value: 'something' }
        }
      end

      it 'returns original key value' do
        expect(subject.extend!).to eq(value: 'something')
      end

      it 'does not mutate orignal context' do
        original = hash.deep_dup

        subject.extend!

        expect(hash).to eq original
      end
    end

    context 'when circular depenency gets detected' do
      let(:hash) do
        { test: { extends: 'test' } }
      end

      it 'raises an error' do
        expect { subject.extend! }
          .to raise_error(StandardError, /Circular dependency detected/)
      end
    end
  end
end
