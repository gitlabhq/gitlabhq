# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Config, feature_category: :pipeline_composition do
  subject { described_class.new(YAML.safe_load(config)) }

  let(:config) do
    <<~CFG
    test:
      spec:
        env: $[[ inputs.env ]]

    $[[ inputs.key ]]:
      name: $[[ inputs.key ]]
      script: my-value
    CFG
  end

  describe '.fabricate' do
    subject { described_class.fabricate(config) }

    context 'when given an Interpolation::Config' do
      let(:config) { described_class.new(YAML.safe_load('yaml:')) }

      it 'returns the given config' do
        is_expected.to be(config)
      end
    end

    context 'when given an unknown object' do
      let(:config) { [] }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'unknown interpolation config')
      end
    end
  end

  describe '#replace!' do
    it 'replaces each of the nodes with a block return value' do
      result = subject.replace! { |node| "abc#{node}cde" }

      expect(result).to eq({
        'abctestcde' => { 'abcspeccde' => { 'abcenvcde' => 'abc$[[ inputs.env ]]cde' } },
        'abc$[[ inputs.key ]]cde' => {
          'abcnamecde' => 'abc$[[ inputs.key ]]cde',
          'abcscriptcde' => 'abcmy-valuecde'
        }
      })
      expect(subject.to_h).to eq({
        '$[[ inputs.key ]]' => { 'name' => '$[[ inputs.key ]]', 'script' => 'my-value' },
        'test' => { 'spec' => { 'env' => '$[[ inputs.env ]]' } }
      })
    end

    context 'when the block return value is an array' do
      context 'when the node is not an array item' do
        let(:config) do
          <<~CFG
            rules: REPLACE
          CFG
        end

        it 'replaces the node with the array' do
          result = subject.replace! do |node|
            next node unless node == 'REPLACE'

            ['test']
          end

          expect(result).to eq({ 'rules' => ['test'] })
        end
      end

      context 'when the node is an array item' do
        let(:config) do
          <<~CFG
            rules:
              - rule 1
              - REPLACE
              - rule 3
          CFG
        end

        it 'inserts the input value into the array' do
          result = subject.replace! do |node|
            next node unless node == 'REPLACE'

            ['rule 2']
          end

          expect(result).to eq({ 'rules' => ['rule 1', 'rule 2', 'rule 3'] })
        end
      end
    end

    context 'when config size is exceeded' do
      before do
        stub_const("#{described_class}::MAX_NODES", 7)
      end

      it 'returns a config size error' do
        replaced = 0

        subject.replace! { replaced += 1 }

        expect(replaced).to eq 4
        expect(subject.errors.size).to eq 1
        expect(subject.errors.first).to eq 'config too large'
      end
    end

    context 'when node size is exceeded' do
      before do
        stub_const("#{described_class}::MAX_NODE_SIZE", 1)
      end

      it 'returns a config size error' do
        subject.replace! { |node| "abc#{node}cde" }

        expect(subject.errors.size).to eq 1
        expect(subject.errors.first).to eq 'config node too large'
      end
    end
  end
end
