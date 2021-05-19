# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Default do
  let(:config) { {} }
  let(:entry) { described_class.new(config) }

  it_behaves_like 'with inheritable CI config' do
    let(:inheritable_key) { nil }
    let(:inheritable_class) { Gitlab::Ci::Config::Entry::Root }

    # These are entries defined in Root
    # that we know that we don't want to inherit
    # as they do not have sense in context of Default
    let(:ignored_inheritable_columns) do
      %i[default include variables stages types workflow]
    end
  end

  describe '.nodes' do
    it 'returns a hash' do
      expect(described_class.nodes).to be_a(Hash)
    end

    context 'when filtering all the entry/node names' do
      it 'contains the expected node names' do
        expect(described_class.nodes.keys)
          .to match_array(%i[before_script image services
                             after_script cache interruptible
                             timeout retry tags artifacts])
      end
    end
  end

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when default entry value is correct' do
      let(:config) { { before_script: ['rspec'] } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when default entry is empty' do
      let(:config) { {} }

      describe '#valid' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when default entry is not correct' do
      context 'incorrect config value type' do
        let(:config) { ['incorrect'] }

        describe '#errors' do
          it 'reports error about a config type' do
            expect(entry.errors)
              .to include 'default config should be a hash'
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

  describe '#compose!' do
    let(:specified) do
      double('specified', 'specified?' => true, value: 'specified')
    end

    let(:unspecified) { double('unspecified', 'specified?' => false) }
    let(:deps) { double('deps', '[]' => unspecified) }

    context 'when default entry inherits configuration from root' do
      let(:config) do
        { image: 'some_image' }
      end

      before do
        allow(deps).to receive('[]').with(:image).and_return(specified)
      end

      it 'raises error' do
        expect { entry.compose!(deps) }.to raise_error(
          Gitlab::Ci::Config::Entry::Default::InheritError)
      end
    end

    context 'when default entry inherits a non-defined configuration from root' do
      let(:config) do
        { image: 'some_image' }
      end

      before do
        allow(deps).to receive('[]').with(:after_script).and_return(specified)

        entry.compose!(deps)
      end

      it 'inherits non-defined configuration entries' do
        expect(entry[:image].value).to eq(name: 'some_image')
        expect(entry[:after_script].value).to eq('specified')
      end
    end
  end
end
