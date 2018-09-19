require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Reports do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when entry config value is correct' do
      let(:config) { { junit: %w[junit.xml] } }

      describe '#value' do
        it 'returns artifacs configuration' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when value is not array' do
        let(:config) { { junit: 'junit.xml' } }

        it 'converts to array' do
          expect(entry.value).to eq({ junit: ['junit.xml'] } )
        end
      end
    end

    context 'when entry value is not correct' do
      describe '#errors' do
        context 'when value of attribute is invalid' do
          let(:config) { { junit: 10 } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'reports junit should be an array of strings or a string'
          end
        end

        context 'when there is an unknown key present' do
          let(:config) { { codeclimate: 'codeclimate.json' } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'reports config contains unknown keys: codeclimate'
          end
        end
      end
    end
  end
end
