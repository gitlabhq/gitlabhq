# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Interpolation::Template, feature_category: :pipeline_composition do
  subject { described_class.new(YAML.safe_load(config), ctx) }

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

  let(:ctx) do
    { inputs: { env: 'dev', key: 'abc' } }
  end

  it 'collects interpolation blocks' do
    expect(subject.size).to eq 2
  end

  it 'interpolates the values properly' do
    expect(subject.interpolated).to eq YAML.safe_load <<~RESULT
    test:
      spec:
        env: dev

    abc:
      name: abc
      script: my-value
    RESULT
  end

  context 'when interpolation can not be performed' do
    let(:config) { '$[[ xxx.yyy ]]: abc' }

    it 'does not interpolate the config' do
      expect(subject).not_to be_valid
      expect(subject.interpolated).to be_nil
    end
  end

  context 'when template consists of nested arrays with hashes and values' do
    let(:config) do
      <<~CFG
      test:
        - a-$[[ inputs.key ]]-b
        - c-$[[ inputs.key ]]-d:
            d-$[[ inputs.key ]]-e
          val: 1
      CFG
    end

    it 'performs a valid interpolation' do
      result = { 'test' => ['a-abc-b', { 'c-abc-d' => 'd-abc-e', 'val' => 1 }] }

      expect(subject).to be_valid
      expect(subject.interpolated).to eq result
    end
  end

  context 'when template contains symbols that need interpolation' do
    subject do
      described_class.new({ '$[[ inputs.key ]]'.to_sym => 'cde' }, ctx)
    end

    it 'performs a valid interpolation' do
      expect(subject).to be_valid
      expect(subject.interpolated).to eq({ 'abc' => 'cde' })
    end
  end

  context 'when template is too large' do
    before do
      stub_const('Gitlab::Ci::Interpolation::Config::MAX_NODES', 1)
    end

    it 'returns an error' do
      expect(subject.interpolated).to be_nil
      expect(subject.errors.count).to eq 1
      expect(subject.errors.first).to eq 'config too large'
    end
  end

  context 'when there are too many interpolation blocks' do
    before do
      stub_const("#{described_class}::MAX_BLOCKS", 1)
    end

    it 'returns an error' do
      expect(subject.interpolated).to be_nil
      expect(subject.errors.count).to eq 1
      expect(subject.errors.first).to eq 'too many interpolation blocks'
    end
  end
end
