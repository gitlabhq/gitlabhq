# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Interpolation::Block, feature_category: :pipeline_composition do
  subject { described_class.new(block, data, ctx) }

  let(:data) do
    'inputs.data'
  end

  let(:block) do
    "$[[ #{data} ]]"
  end

  let(:ctx) do
    { inputs: { data: 'abc' }, env: { 'ENV' => 'dev' } }
  end

  it 'knows its content' do
    expect(subject.content).to eq 'inputs.data'
  end

  it 'properly evaluates the access pattern' do
    expect(subject.value).to eq 'abc'
  end

  describe '.match' do
    it 'matches each block in a string' do
      expect { |b| described_class.match('$[[ access1 ]] $[[ access2 ]]', &b) }
        .to yield_successive_args(['$[[ access1 ]]', 'access1'], ['$[[ access2 ]]', 'access2'])
    end

    it 'matches an empty block' do
      expect { |b| described_class.match('$[[]]', &b) }
        .to yield_with_args('$[[]]', '')
    end
  end
end
