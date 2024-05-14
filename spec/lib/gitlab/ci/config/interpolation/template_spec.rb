# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Template, feature_category: :pipeline_composition do
  subject { described_class.new(YAML.safe_load(config), ctx) }

  let(:config) do
    <<~CFG
    test:
      spec:
        env: $[[ inputs.env ]]

    $[[ inputs.key ]]:
      name: $[[ inputs.key ]]
      parallel: $[[ inputs.parallel ]]
      allow_failure: $[[ inputs.allow_failure ]]
      script: 'echo "This job makes $[[ inputs.parallel ]] jobs for the $[[ inputs.env ]] env"'
    CFG
  end

  let(:ctx) do
    { inputs: { allow_failure: true, env: 'dev', key: 'abc', parallel: 6 } }
  end

  it 'collects interpolation blocks' do
    expect(subject.size).to eq 4
  end

  it 'interpolates the values properly' do
    expect(subject.interpolated).to eq YAML.safe_load <<~RESULT
    test:
      spec:
        env: dev

    abc:
      name: abc
      parallel: 6
      allow_failure: true
      script: 'echo "This job makes 6 jobs for the dev env"'
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
      described_class.new({ '$[[ inputs.key ]]': 'cde' }, ctx)
    end

    it 'performs a valid interpolation' do
      expect(subject).to be_valid
      expect(subject.interpolated).to eq({ 'abc' => 'cde' })
    end
  end

  context 'when template is too large' do
    before do
      stub_const('Gitlab::Ci::Config::Interpolation::Config::MAX_NODES', 1)
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
