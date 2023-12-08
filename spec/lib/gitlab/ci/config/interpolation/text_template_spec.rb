# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::TextTemplate, feature_category: :pipeline_composition do
  subject(:template) { described_class.new(config, ctx) }

  let(:config) do
    <<~CFG
    test:
      spec:
        env: $[[ inputs.env ]]

    $[[ inputs.key ]]:
      name: $[[ inputs.key ]]
      script: my-value
      parallel: $[[ inputs.parallel ]]
    CFG
  end

  let(:ctx) do
    { inputs: { env: 'dev', key: 'abc', parallel: 6 } }
  end

  it 'interpolates the values properly' do
    expect(template.interpolated).to eq <<~RESULT
    test:
      spec:
        env: dev

    abc:
      name: abc
      script: my-value
      parallel: 6
    RESULT
  end

  context 'when the config has an unknown interpolation key' do
    let(:config) { '$[[ xxx.yyy ]]: abc' }

    it 'does not interpolate the config' do
      expect(template).not_to be_valid
      expect(template.interpolated).to be_nil
      expect(template.errors).to contain_exactly('unknown interpolation key: `xxx`')
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
      result = <<~RESULT
      test:
        - a-abc-b
        - c-abc-d:
            d-abc-e
          val: 1
      RESULT

      expect(template).to be_valid
      expect(template.interpolated).to eq result
    end
  end

  context 'when template contains symbols that need interpolation' do
    subject(:template) do
      described_class.new("'$[[ inputs.key ]]': 'cde'", ctx)
    end

    it 'performs a valid interpolation' do
      expect(template).to be_valid
      expect(template.interpolated).to eq("'abc': 'cde'")
    end
  end

  context 'when template is too large' do
    before do
      stub_application_setting(ci_max_total_yaml_size_bytes: 1)
    end

    it 'returns an error' do
      expect(template.interpolated).to be_nil
      expect(template.errors).to contain_exactly('config too large')
    end
  end

  context 'when there are too many interpolation blocks' do
    before do
      stub_const("#{described_class}::MAX_BLOCKS", 1)
    end

    it 'returns an error' do
      expect(template.interpolated).to be_nil
      expect(template.errors).to contain_exactly('too many interpolation blocks')
    end
  end
end
