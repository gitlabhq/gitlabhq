# frozen_string_literal: true

require 'spec_helper'

describe ExpandVariables do
  describe '#expand' do
    context 'table tests' do
      using RSpec::Parameterized::TableSyntax

      where do
        {
          "no expansion": {
            value: 'key',
            result: 'key',
            variables: []
          },
          "missing variable": {
            value: 'key$variable',
            result: 'key',
            variables: []
          },
          "simple expansion": {
            value: 'key$variable',
            result: 'keyvalue',
            variables: [
              { key: 'variable', value: 'value' }
            ]
          },
          "simple with hash of variables": {
            value: 'key$variable',
            result: 'keyvalue',
            variables: {
              'variable' => 'value'
            }
          },
          "complex expansion": {
            value: 'key${variable}',
            result: 'keyvalue',
            variables: [
              { key: 'variable', value: 'value' }
            ]
          },
          "simple expansions": {
            value: 'key$variable$variable2',
            result: 'keyvalueresult',
            variables: [
              { key: 'variable', value: 'value' },
              { key: 'variable2', value: 'result' }
            ]
          },
          "complex expansions": {
            value: 'key${variable}${variable2}',
            result: 'keyvalueresult',
            variables: [
              { key: 'variable', value: 'value' },
              { key: 'variable2', value: 'result' }
            ]
          },
          "complex expansions with missing variable": {
            value: 'key${variable}${variable2}',
            result: 'keyvalue',
            variables: [
              { key: 'variable', value: 'value' }
            ]
          },
          "out-of-order expansion": {
            value: 'key$variable2$variable',
            result: 'keyresultvalue',
            variables: [
              { key: 'variable', value: 'value' },
              { key: 'variable2', value: 'result' }
            ]
          },
          "out-of-order complex expansion": {
            value: 'key${variable2}${variable}',
            result: 'keyresultvalue',
            variables: [
              { key: 'variable', value: 'value' },
              { key: 'variable2', value: 'result' }
            ]
          },
          "review-apps expansion": {
            value: 'review/$CI_COMMIT_REF_NAME',
            result: 'review/feature/add-review-apps',
            variables: [
              { key: 'CI_COMMIT_REF_NAME', value: 'feature/add-review-apps' }
            ]
          },
          "do not lazily access variables when no expansion": {
            value: 'key',
            result: 'key',
            variables: -> { raise NotImplementedError }
          },
          "lazily access variables": {
            value: 'key$variable',
            result: 'keyvalue',
            variables: -> { [{ key: 'variable', value: 'value' }] }
          }
        }
      end

      with_them do
        subject { ExpandVariables.expand(value, variables) }

        it { is_expected.to eq(result) }
      end
    end

    context 'lazily inits variables' do
      let(:variables) { -> { [{ key: 'variable', value: 'result' }] } }

      subject { described_class.expand(value, variables) }

      context 'when expanding variable' do
        let(:value) { 'key$variable$variable2' }

        it 'calls block at most once' do
          expect(variables).to receive(:call).once.and_call_original

          is_expected.to eq('keyresult')
        end
      end

      context 'when no expansion is needed' do
        let(:value) { 'key' }

        it 'does not call block' do
          expect(variables).not_to receive(:call)

          is_expected.to eq('key')
        end
      end
    end
  end
end
