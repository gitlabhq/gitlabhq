# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require 'tsort'

RSpec.describe Gitlab::Ci::Variables::Collection::Sort do
  describe '#initialize with non-Collection value' do
    subject { described_class.new([]) }

    it 'raises ArgumentError' do
      expect { subject }.to raise_error(ArgumentError, /Collection object was expected/)
    end
  end

  describe '#errors' do
    context 'table tests' do
      using RSpec::Parameterized::TableSyntax

      where do
        {
          "empty array": {
            variables: [],
            expected_errors: nil
          },
          "simple expansions": {
            variables: [
              { key: 'variable', value: 'value' },
              { key: 'variable2', value: 'result' },
              { key: 'variable3', value: 'key$variable$variable2' }
            ],
            expected_errors: nil
          },
          "cyclic dependency": {
            variables: [
              { key: 'variable', value: '$variable2' },
              { key: 'variable2', value: '$variable3' },
              { key: 'variable3', value: 'key$variable$variable2' }
            ],
            expected_errors: 'circular variable reference detected: ["variable", "variable2", "variable3"]'
          },
          "array with raw variable": {
            variables: [
              { key: 'variable', value: '$variable2' },
              { key: 'variable2', value: '$variable3' },
              { key: 'variable3', value: 'key$variable$variable2', raw: true }
            ],
            expected_errors: nil
          },
          "variable containing escaped variable reference": {
            variables: [
              { key: 'variable_b', value: '$$variable_a' },
              { key: 'variable_c', value: '$variable_a' },
              { key: 'variable_a', value: 'value' }
            ],
            expected_errors: nil
          }
        }
      end

      with_them do
        let(:collection) { Gitlab::Ci::Variables::Collection.new(variables) }

        subject { Gitlab::Ci::Variables::Collection::Sort.new(collection) }

        it 'errors matches expected errors' do
          expect(subject.errors).to eq(expected_errors)
        end

        it 'valid? matches expected errors' do
          expect(subject.valid?).to eq(expected_errors.nil?)
        end

        it 'does not raise' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe '#tsort' do
    context 'table tests' do
      using RSpec::Parameterized::TableSyntax

      where do
        {
          "empty array": {
            variables: [],
            result: []
          },
          "simple expansions, no reordering needed": {
            variables: [
              { key: 'variable', value: 'value' },
              { key: 'variable2', value: 'result' },
              { key: 'variable3', value: 'key$variable$variable2' }
            ],
            result: %w[variable variable2 variable3]
          },
          "complex expansion, reordering needed": {
            variables: [
              { key: 'variable2', value: 'key${variable}' },
              { key: 'variable', value: 'value' }
            ],
            result: %w[variable variable2]
          },
          "unused variables": {
            variables: [
              { key: 'variable', value: 'value' },
              { key: 'variable4', value: 'key$variable$variable3' },
              { key: 'variable2', value: 'result2' },
              { key: 'variable3', value: 'result3' }
            ],
            result: %w[variable variable3 variable4 variable2]
          },
          "missing variable": {
            variables: [
              { key: 'variable2', value: 'key$variable' }
            ],
            result: %w[variable2]
          },
          "complex expansions with missing variable": {
            variables: [
              { key: 'variable4', value: 'key${variable}${variable2}${variable3}' },
              { key: 'variable', value: 'value' },
              { key: 'variable3', value: 'value3' }
            ],
            result: %w[variable variable3 variable4]
          },
          "raw variable does not get resolved": {
            variables: [
              { key: 'variable', value: '$variable2' },
              { key: 'variable2', value: '$variable3' },
              { key: 'variable3', value: 'key$variable$variable2', raw: true }
            ],
            result: %w[variable3 variable2 variable]
          },
          "variable containing escaped variable reference": {
            variables: [
              { key: 'variable_b', value: '$$variable_a' },
              { key: 'variable_c', value: '$variable_a' },
              { key: 'variable_a', value: 'value' }
            ],
            result: %w[variable_b variable_a variable_c]
          }
        }
      end

      with_them do
        let(:collection) { Gitlab::Ci::Variables::Collection.new(variables) }

        subject { Gitlab::Ci::Variables::Collection::Sort.new(collection).tsort }

        it 'returns correctly sorted variables' do
          expect(subject.pluck(:key)).to eq(result)
        end
      end
    end

    context 'cyclic dependency' do
      let(:variables) do
        [
          { key: 'variable2', value: '$variable3' },
          { key: 'variable3', value: 'key$variable$variable2' },
          { key: 'variable', value: '$variable2' }
        ]
      end

      let(:collection) { Gitlab::Ci::Variables::Collection.new(variables) }

      subject { described_class.new(collection).tsort }

      it 'raises TSort::Cyclic' do
        expect { subject }.to raise_error(TSort::Cyclic)
      end
    end

    context 'with overridden variables' do
      let(:variables) do
        [
          { key: 'PROJECT_VAR',          value: '$SUBGROUP_VAR' },
          { key: 'SUBGROUP_VAR',         value: '$TOP_LEVEL_GROUP_NAME' },
          { key: 'SUBGROUP_VAR',         value: '$SUB_GROUP_NAME' },
          { key: 'TOP_LEVEL_GROUP_NAME', value: 'top-level-group' },
          { key: 'SUB_GROUP_NAME',       value: 'vars-in-vars-subgroup' }
        ]
      end

      let(:collection) { Gitlab::Ci::Variables::Collection.new(variables) }

      subject do
        Gitlab::Ci::Variables::Collection::Sort.new(collection).tsort.map { |v| { v[:key] => v.value } }
      end

      it 'preserves relative order of overridden variables' do
        is_expected.to eq(
          [
            { 'TOP_LEVEL_GROUP_NAME' => 'top-level-group' },
            { 'SUBGROUP_VAR'         => '$TOP_LEVEL_GROUP_NAME' },
            { 'SUB_GROUP_NAME'       => 'vars-in-vars-subgroup' },
            { 'SUBGROUP_VAR'         => '$SUB_GROUP_NAME' },
            { 'PROJECT_VAR'          => '$SUBGROUP_VAR' }
          ])
      end
    end
  end
end
