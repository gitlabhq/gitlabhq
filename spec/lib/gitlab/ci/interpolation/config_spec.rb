# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Interpolation::Config, feature_category: :pipeline_composition do
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

  describe '#replace!' do
    it 'replaces each od the nodes with a block return value' do
      result = subject.replace! { |node| "abc#{node}cde" }

      expect(result).to eq({
        'abctestcde' => { 'abcspeccde' => { 'abcenvcde' => 'abc$[[ inputs.env ]]cde' } },
        'abc$[[ inputs.key ]]cde' => {
          'abcnamecde' => 'abc$[[ inputs.key ]]cde',
          'abcscriptcde' => 'abcmy-valuecde'
        }
      })
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
end
