# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Rules do
  let(:rule_hashes) {}

  subject(:rules) { described_class.new(rule_hashes) }

  describe '#evaluate' do
    let(:context) { double(variables: {}) }

    subject(:result) { rules.evaluate(context).pass? }

    context 'when there is no rule' do
      it { is_expected.to eq(true) }
    end

    context 'when there is a rule' do
      let(:rule_hashes) { [{ if: '$MY_VAR == "hello"' }] }

      context 'when the rule matches' do
        let(:context) { double(variables: { MY_VAR: 'hello' }) }

        it { is_expected.to eq(true) }
      end

      context 'when the rule does not match' do
        let(:context) { double(variables: { MY_VAR: 'invalid' }) }

        it { is_expected.to eq(false) }
      end
    end
  end
end
