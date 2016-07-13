require 'spec_helper'

describe Gitlab::Ci::Config::Node::Stage do
  let(:stage) { described_class.new(config, global: global) }
  let(:global) { spy('Global') }

  describe 'validations' do
    context 'when stage config value is correct' do
      let(:config) { 'build' }

      before do
        allow(global).to receive(:stages).and_return(%w[build])
      end

      describe '#value' do
        it 'returns a stage key' do
          expect(stage.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(stage).to be_valid
        end
      end
    end

    context 'when stage config is incorrect' do
      describe '#errors' do
        context 'when reference to global node is not set' do
          let(:stage) { described_class.new('test') }

          it 'raises error' do
            expect { stage.validate! }.to raise_error(
              Gitlab::Ci::Config::Node::Entry::InvalidError,
              /Entry needs global attribute set internally./
            )
          end
        end

        context 'when value has a wrong type' do
          let(:config) { { test: true } }

          it 'reports errors about wrong type' do
            expect(stage.errors)
              .to include 'stage config should be a string'
          end
        end

        context 'when stage is not present in global configuration' do
          let(:config) { 'unknown' }

          before do
            allow(global)
              .to receive(:stages).and_return(%w[test deploy])
          end

          it 'reports error about missing stage' do
            stage.validate!

            expect(stage.errors)
              .to include 'stage config should be one of ' \
                          'defined stages (test, deploy)'
          end
        end
      end
    end
  end

  describe '#known?' do
    before do
      allow(global).to receive(:stages).and_return(%w[test deploy])
    end

    context 'when stage is not known' do
      let(:config) { :unknown }

      it 'returns false' do
        expect(stage.known?).to be false
      end
    end

    context 'when stage is known' do
      let(:config) { 'test' }

      it 'returns false' do
        expect(stage.known?).to be true
      end
    end
  end

  describe '.default' do
    it 'returns default stage' do
      expect(described_class.default).to eq 'test'
    end
  end
end
