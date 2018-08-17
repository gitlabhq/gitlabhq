require 'fast_spec_helper'

describe Gitlab::Ci::Config::Extendable::Collection do
  subject { described_class.new(hash) }

  describe '#each' do
    context 'when there is extendable entry in the hash' do
      let(:test) do
        { extends: 'something', only: %w[master] }
      end

      let(:hash) do
        { something: { script: 'ls' }, test: test }
      end

      it 'yields control' do
        expect { |b| subject.each(&b) }.to yield_control
      end
    end
  end

  describe '#to_hash' do
    context 'when a hash has a single simple extension' do
      let(:hash) do
        {
          something: {
            script: 'deploy',
            only: { variables: %w[$SOMETHING] }
          },

          test: {
            extends: 'something',
            script: 'ls',
            only: { refs: %w[master] }
          }
        }
      end

      it 'extends a hash with a deep reverse merge' do
        expect(subject.to_hash).to eq(
          something: {
            script: 'deploy',
            only: { variables: %w[$SOMETHING] }
          },

          test: {
            extends: 'something',
            script: 'ls',
            only: {
              refs: %w[master],
              variables: %w[$SOMETHING]
            }
          }
        )
      end
    end

    context 'when a hash uses recursive extensions' do
      let(:hash) do
        {
          test: {
            extends: 'something',
            script: 'ls',
            only: { refs: %w[master] }
          },

          something: {
            extends: '.first',
            script: 'deploy',
            only: { variables: %w[$SOMETHING] }
          },

          '.first': {
            script: 'run',
            only: { kubernetes: 'active' }
          }
        }
      end

      it 'extends a hash with a deep reverse merge' do
        expect(subject.to_hash).to eq(
          '.first': {
            script: 'run',
            only: { kubernetes: 'active' }
          },

          something: {
            extends: '.first',
            script: 'deploy',
            only: {
              kubernetes: 'active',
              variables: %w[$SOMETHING]
            }
          },

          test: {
            extends: 'something',
            script: 'ls',
            only: {
              refs: %w[master],
              variables: %w[$SOMETHING],
              kubernetes: 'active'
            }
          }
        )
      end
    end

    context 'when nested circular dependecy has been detected' do
      let(:hash) do
        {
          test: {
            extends: 'something',
            script: 'ls',
            only: { refs: %w[master] }
          },

          something: {
            extends: '.first',
            script: 'deploy',
            only: { variables: %w[$SOMETHING] }
          },

          '.first': {
            extends: 'something',
            script: 'run',
            only: { kubernetes: 'active' }
          }
        }
      end

      it 'raises an error about circular dependency' do
        expect { subject.to_hash }
          .to raise_error(described_class::CircularDependencyError)
      end
    end

    context 'when circular dependecy to self has been detected' do
      let(:hash) do
        {
          test: {
            extends: 'test',
            script: 'ls',
            only: { refs: %w[master] }
          }
        }
      end

      it 'raises an error about circular dependency' do
        expect { subject.to_hash }
          .to raise_error(described_class::CircularDependencyError)
      end
    end

    context 'when invalid extends value is specified' do
      let(:hash) do
        { something: { extends: 1, script: 'ls' } }
      end

      it 'raises an error about invalid extension' do
        expect { subject.to_hash }
          .to raise_error(described_class::InvalidExtensionError)
      end
    end
  end
end
