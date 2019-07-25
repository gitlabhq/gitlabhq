# frozen_string_literal: true

require 'spec_helper'

describe ExpandVariables do
  describe '#expand' do
    subject { described_class.expand(value, variables) }

    tests = [
      { value: 'key',
        result: 'key',
        variables: [] },
      { value: 'key$variable',
        result: 'key',
        variables: [] },
      { value: 'key$variable',
        result: 'keyvalue',
        variables: [
          { key: 'variable', value: 'value' }
        ] },
      { value: 'key${variable}',
        result: 'keyvalue',
        variables: [
          { key: 'variable', value: 'value' }
        ] },
      { value: 'key$variable$variable2',
        result: 'keyvalueresult',
        variables: [
          { key: 'variable', value: 'value' },
          { key: 'variable2', value: 'result' }
        ] },
      { value: 'key${variable}${variable2}',
        result: 'keyvalueresult',
        variables: [
          { key: 'variable', value: 'value' },
          { key: 'variable2', value: 'result' }
        ] },
      { value: 'key$variable2$variable',
        result: 'keyresultvalue',
        variables: [
          { key: 'variable', value: 'value' },
          { key: 'variable2', value: 'result' }
        ] },
      { value: 'key${variable2}${variable}',
        result: 'keyresultvalue',
        variables: [
          { key: 'variable', value: 'value' },
          { key: 'variable2', value: 'result' }
        ] },
      { value: 'review/$CI_COMMIT_REF_NAME',
        result: 'review/feature/add-review-apps',
        variables: [
          { key: 'CI_COMMIT_REF_NAME', value: 'feature/add-review-apps' }
        ] }
    ]

    tests.each do |test|
      context "#{test[:value]} resolves to #{test[:result]}" do
        let(:value) { test[:value] }
        let(:variables) { test[:variables] }

        it { is_expected.to eq(test[:result]) }
      end
    end
  end
end
