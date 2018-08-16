require 'fast_spec_helper'

describe Gitlab::Ci::Config::Extendable do
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
        expect { |b| subject.each(&b) }
          .to yield_with_args(:test, :something, test)
      end
    end

    pending 'when not extending using a hash'
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

      it 'extends a hash with reverse merge' do
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

    pending 'when a hash recursive extensions'

    pending 'when invalid `extends` is specified'
  end
end
