require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Job do
  let(:entry) { described_class.new(config, name: :rspec) }

  describe 'validations' do
    before { entry.compose! }

    context 'when entry config value is correct' do
      let(:config) { { script: 'rspec' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when job name is empty' do
        let(:entry) { described_class.new(config, name: ''.to_sym) }

        it 'reports error' do
          expect(entry.errors)
            .to include "job name can't be blank"
        end
      end
    end

    context 'when entry value is not correct' do
      context 'incorrect config value type' do
        let(:config) { ['incorrect'] }

        describe '#errors' do
          it 'reports error about a config type' do
            expect(entry.errors)
              .to include 'job config should be a hash'
          end
        end
      end

      context 'when config is empty' do
        let(:config) { {} }

        describe '#valid' do
          it 'is invalid' do
            expect(entry).not_to be_valid
          end
        end
      end

      context 'when unknown keys detected' do
        let(:config) { { unknown: true } }

        describe '#valid' do
          it 'is not valid' do
            expect(entry).not_to be_valid
          end
        end
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      expect(entry).to be_relevant
    end
  end

  describe '#compose!' do
    let(:unspecified) { double('unspecified', 'specified?' => false) }

    let(:specified) do
      double('specified', 'specified?' => true, value: 'specified')
    end

    let(:deps) { double('deps', '[]' => unspecified) }

    context 'when job config overrides global config' do
      before { entry.compose!(deps) }

      let(:config) do
        { image: 'some_image', cache: { key: 'test' } }
      end

      it 'overrides global config' do
        expect(entry[:image].value).to eq 'some_image'
        expect(entry[:cache].value).to eq(key: 'test')
      end
    end

    context 'when job config does not override global config' do
      before do
        allow(deps).to receive('[]').with(:image).and_return(specified)
        entry.compose!(deps)
      end

      let(:config) { { script: 'ls', cache: { key: 'test' } } }

      it 'uses config from global entry' do
        expect(entry[:image].value).to eq 'specified'
        expect(entry[:cache].value).to eq(key: 'test')
      end
    end
  end

  context 'when composed' do
    before { entry.compose! }

    describe '#value' do
      before { entry.compose! }

      context 'when entry is correct' do
        let(:config) do
          { before_script: %w[ls pwd],
            script: 'rspec',
            after_script: %w[cleanup] }
        end

        it 'returns correct value' do
          expect(entry.value)
            .to eq(name: :rspec,
                   before_script: %w[ls pwd],
                   script: %w[rspec],
                   commands: "ls\npwd\nrspec",
                   stage: 'test',
                   after_script: %w[cleanup])
        end
      end
    end

    describe '#commands' do
      let(:config) do
        { before_script: %w[ls pwd], script: 'rspec' }
      end

      it 'returns a string of commands concatenated with new line character' do
        expect(entry.commands).to eq "ls\npwd\nrspec"
      end
    end
  end
end
