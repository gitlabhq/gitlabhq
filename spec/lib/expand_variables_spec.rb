# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe ExpandVariables, feature_category: :ci_variables do
  shared_examples 'common variable expansion' do |expander|
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "no expansion": {
          value: 'key',
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
        "expansion using %": {
          value: 'key%variable%',
          result: 'keyvalue',
          variables: [
            { key: 'variable', value: 'value' }
          ]
        },
        "multiple simple expansions": {
          value: 'key$variable$variable2',
          result: 'keyvalueresult',
          variables: [
            { key: 'variable', value: 'value' },
            { key: 'variable2', value: 'result' }
          ]
        },
        "multiple complex expansions": {
          value: 'key${variable}${variable2}',
          result: 'keyvalueresult',
          variables: [
            { key: 'variable', value: 'value' },
            { key: 'variable2', value: 'result' }
          ]
        },
        "nested expansion is not expanded": {
          value: 'key$variable$variable2',
          result: 'keyvalue$variable3',
          variables: [
            { key: 'variable', value: 'value' },
            { key: 'variable2', value: '$variable3' },
            { key: 'variable3', value: 'result' }
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
        },
        "simple expansion using Collection": {
          value: 'key$variable',
          result: 'keyvalue',
          variables: Gitlab::Ci::Variables::Collection.new([{ key: 'variable', value: 'value' }])
        }
      }
    end

    with_them do
      subject { expander.call(value, variables) }

      it { is_expected.to eq(result) }
    end
  end

  shared_examples 'file variable expansion with expand_file_refs true' do |expander|
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "simple with a file variable": {
          value: 'key$variable',
          result: 'keyvalue',
          variables: [
            { key: 'variable', value: 'value', file: true }
          ]
        },
        "complex expansion with a file variable": {
          value: 'key${variable}',
          result: 'keyvalue',
          variables: [
            { key: 'variable', value: 'value', file: true }
          ]
        },
        "expansion using % with a file variable": {
          value: 'key%variable%',
          result: 'keyvalue',
          variables: [
            { key: 'variable', value: 'value', file: true }
          ]
        }
      }
    end

    with_them do
      subject { expander.call(value, variables, expand_file_refs: true) }

      it { is_expected.to eq(result) }
    end
  end

  shared_examples 'file variable expansion with expand_file_refs false' do |expander|
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "simple with a file variable": {
          value: 'key$variable',
          result: 'key$variable',
          variables: [
            { key: 'variable', value: 'value', file: true }
          ]
        },
        "complex expansion with a file variable": {
          value: 'key${variable}',
          result: 'key${variable}',
          variables: [
            { key: 'variable', value: 'value', file: true }
          ]
        },
        "expansion using % with a file variable": {
          value: 'key%variable%',
          result: 'key%variable%',
          variables: [
            { key: 'variable', value: 'value', file: true }
          ]
        }
      }
    end

    with_them do
      subject { expander.call(value, variables, expand_file_refs: false) }

      it { is_expected.to eq(result) }
    end
  end

  shared_examples 'masked variable expansion with fail_on_masked true' do |expander|
    using RSpec::Parameterized::TableSyntax

    subject { expander.call(value, variables, fail_on_masked: true) }

    where do
      {
        'simple expansion with a masked variable': {
          value: 'key$variable',
          variables: [
            { key: 'variable', value: 'value', masked: true }
          ]
        },
        'complex expansion with a masked variable': {
          value: 'key${variable}${variable2}',
          variables: [
            { key: 'variable', value: 'value', masked: true },
            { key: 'variable2', value: 'result', masked: false }
          ]
        },
        'expansion using % with a masked variable': {
          value: 'key%variable%',
          variables: [
            { key: 'variable', value: 'value', masked: true }
          ]
        }
      }
    end

    with_them do
      it 'raises an error' do
        expect { subject }.to raise_error(
          ExpandVariables::VariableExpansionError, /masked variables cannot be expanded/
        )
      end
    end

    context 'expansion without a masked variable' do
      let(:value) { 'key$variable${variable2}' }

      let(:variables) do
        [
          { key: 'variable', value: 'value', masked: false },
          { key: 'variable2', value: 'result', masked: false }
        ]
      end

      it { is_expected.to eq('keyvalueresult') }
    end
  end

  shared_examples 'masked variable expansion with fail_on_masked false' do |expander|
    using RSpec::Parameterized::TableSyntax

    subject { expander.call(value, variables, fail_on_masked: false) }

    where do
      {
        'simple expansion with a masked variable': {
          value: 'key$variable',
          result: 'keyvalue',
          variables: [
            { key: 'variable', value: 'value', masked: true }
          ]
        },
        'complex expansion with a masked variable': {
          value: 'key${variable}${variable2}',
          result: 'keyvalueresult',
          variables: [
            { key: 'variable', value: 'value', masked: true },
            { key: 'variable2', value: 'result', masked: false }
          ]
        },
        'expansion using % with a masked variable': {
          value: 'key%variable%',
          result: 'keyvalue',
          variables: [
            { key: 'variable', value: 'value', masked: true }
          ]
        },
        'expansion without a masked variable': {
          value: 'key$variable${variable2}',
          result: 'keyvalueresult',
          variables: [
            { key: 'variable', value: 'value', masked: false },
            { key: 'variable2', value: 'result', masked: false }
          ]
        }
      }
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#expand' do
    context 'table tests' do
      it_behaves_like 'common variable expansion', described_class.method(:expand)

      it_behaves_like 'file variable expansion with expand_file_refs true', described_class.method(:expand)

      it_behaves_like 'file variable expansion with expand_file_refs false', described_class.method(:expand)

      it_behaves_like 'masked variable expansion with fail_on_masked true', described_class.method(:expand)

      it_behaves_like 'masked variable expansion with fail_on_masked false', described_class.method(:expand)

      context 'with missing variables' do
        using RSpec::Parameterized::TableSyntax

        where do
          {
            "missing variable": {
              value: 'key$variable',
              result: 'key',
              variables: []
            },
            "complex expansions with missing variable": {
              value: 'key${variable}${variable2}',
              result: 'keyvalue',
              variables: [
                { key: 'variable', value: 'value' }
              ]
            },
            "complex expansions with missing variable for Windows": {
              value: 'key%variable%%variable2%',
              result: 'keyvalue',
              variables: [
                { key: 'variable', value: 'value' }
              ]
            }
          }
        end

        with_them do
          subject { ExpandVariables.expand(value, variables) }

          it { is_expected.to eq(result) }
        end
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

  describe '#expand_existing' do
    context 'table tests' do
      it_behaves_like 'common variable expansion', described_class.method(:expand_existing)

      it_behaves_like 'file variable expansion with expand_file_refs true', described_class.method(:expand_existing)

      it_behaves_like 'file variable expansion with expand_file_refs false', described_class.method(:expand_existing)

      it_behaves_like 'masked variable expansion with fail_on_masked true', described_class.method(:expand)

      it_behaves_like 'masked variable expansion with fail_on_masked false', described_class.method(:expand)

      context 'with missing variables' do
        using RSpec::Parameterized::TableSyntax

        where do
          {
            "missing variable": {
              value: 'key$variable',
              result: 'key$variable',
              variables: []
            },
            "complex expansions with missing variable": {
              value: 'key${variable}${variable2}',
              result: 'keyvalue${variable2}',
              variables: [
                { key: 'variable', value: 'value' }
              ]
            },
            "complex expansions with missing variable for Windows": {
              value: 'key%variable%%variable2%',
              result: 'keyvalue%variable2%',
              variables: [
                { key: 'variable', value: 'value' }
              ]
            }
          }
        end

        with_them do
          subject { ExpandVariables.expand_existing(value, variables) }

          it { is_expected.to eq(result) }
        end
      end
    end

    context 'lazily inits variables' do
      let(:variables) { -> { [{ key: 'variable', value: 'result' }] } }

      subject { described_class.expand_existing(value, variables) }

      context 'when expanding variable' do
        let(:value) { 'key$variable$variable2' }

        it 'calls block at most once' do
          expect(variables).to receive(:call).once.and_call_original

          is_expected.to eq('keyresult$variable2')
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
