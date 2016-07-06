require 'spec_helper'

describe Gitlab::Ci::Config::Node::Jobs do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    before { entry.process! }

    context 'when entry config value is correct' do
      let(:config) { { rspec: { script: 'rspec' } } }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq(rspec: { script: 'rspec' })
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      context 'incorrect config value type' do
        let(:config) { ['incorrect'] }

        describe '#errors' do
          it 'saves errors' do
            expect(entry.errors)
              .to include 'jobs config should be a hash'
          end
        end
      end
    end
  end

  context 'when valid job entries processed' do
    before { entry.process! }

    let(:config) do
      { rspec: { script: 'rspec' },
        spinach: { script: 'spinach' },
        '.hidden'.to_sym => {} }
    end

    describe '#descendants' do
      it 'creates valid descendant nodes' do
        expect(entry.descendants.count).to eq 3
        expect(entry.descendants.first(2))
          .to all(be_an_instance_of(Gitlab::Ci::Config::Node::Job))
        expect(entry.descendants.last)
          .to be_an_instance_of(Gitlab::Ci::Config::Node::HiddenJob)
      end
    end

    describe '#value' do
      it 'returns value of visible jobs only' do
        expect(entry.value.keys).to eq [:rspec, :spinach]
      end
    end
  end
end
