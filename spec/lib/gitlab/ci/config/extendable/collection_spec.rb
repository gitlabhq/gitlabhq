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

      it 'yields the test hash' do
        expect { |b| subject.each(&b) }.to yield_control
      end
    end

    context 'when not extending using a hash' do
      let(:hash) do
        { something: { extends: [1], script: 'ls' } }
      end

      it 'yields invalid extends as well' do
        expect { |b| subject.each(&b) }.to yield_control
      end
    end
  end

  describe '#extend!' do
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
        expect(subject.extend!).to eq(
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
        expect(subject.extend!).to eq(
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

    pending 'when invalid `extends` is specified'
    context 'when circular dependecy has been detected' do
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

      it 'raises an error' do
        expect { subject.extend! }
          .to raise_error(described_class::CircularDependencyError)
      end
    end
  end
end
