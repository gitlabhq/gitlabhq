# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Collection::Sorted do
  describe '#errors' do
    context 'when FF :variable_inside_variable is disabled' do
      let_it_be(:project_with_flag_disabled) { create(:project) }
      let_it_be(:project_with_flag_enabled) { create(:project) }

      before do
        stub_feature_flags(variable_inside_variable: [project_with_flag_enabled])
      end

      context 'table tests' do
        using RSpec::Parameterized::TableSyntax

        where do
          {
            "empty array": {
              variables: []
            },
            "simple expansions": {
              variables: [
                { key: 'variable', value: 'value' },
                { key: 'variable2', value: 'result' },
                { key: 'variable3', value: 'key$variable$variable2' }
              ]
            },
            "complex expansion": {
              variables: [
                { key: 'variable', value: 'value' },
                { key: 'variable2', value: 'key${variable}' }
              ]
            },
            "complex expansions with missing variable for Windows": {
              variables: [
                { key: 'variable', value: 'value' },
                { key: 'variable3', value: 'key%variable%%variable2%' }
              ]
            },
            "out-of-order variable reference": {
              variables: [
                { key: 'variable2', value: 'key${variable}' },
                { key: 'variable', value: 'value' }
              ]
            },
            "array with cyclic dependency": {
              variables: [
                { key: 'variable', value: '$variable2' },
                { key: 'variable2', value: '$variable3' },
                { key: 'variable3', value: 'key$variable$variable2' }
              ]
            }
          }
        end

        with_them do
          subject { Gitlab::Ci::Variables::Collection::Sorted.new(variables, project_with_flag_disabled) }

          it 'does not report error' do
            expect(subject.errors).to eq(nil)
          end

          it 'valid? reports true' do
            expect(subject.valid?).to eq(true)
          end
        end
      end
    end

    context 'when FF :variable_inside_variable is enabled' do
      let_it_be(:project_with_flag_disabled) { create(:project) }
      let_it_be(:project_with_flag_enabled) { create(:project) }

      before do
        stub_feature_flags(variable_inside_variable: [project_with_flag_enabled])
      end

      context 'table tests' do
        using RSpec::Parameterized::TableSyntax

        where do
          {
            "empty array": {
              variables: [],
              validation_result: nil
            },
            "simple expansions": {
              variables: [
                { key: 'variable', value: 'value' },
                { key: 'variable2', value: 'result' },
                { key: 'variable3', value: 'key$variable$variable2' }
              ],
              validation_result: nil
            },
            "cyclic dependency": {
              variables: [
                { key: 'variable', value: '$variable2' },
                { key: 'variable2', value: '$variable3' },
                { key: 'variable3', value: 'key$variable$variable2' }
              ],
              validation_result: 'circular variable reference detected: ["variable", "variable2", "variable3"]'
            }
          }
        end

        with_them do
          subject { Gitlab::Ci::Variables::Collection::Sorted.new(variables, project_with_flag_enabled) }

          it 'errors matches expected validation result' do
            expect(subject.errors).to eq(validation_result)
          end

          it 'valid? matches expected validation result' do
            expect(subject.valid?).to eq(validation_result.nil?)
          end
        end
      end
    end
  end

  describe '#sort' do
    context 'when FF :variable_inside_variable is disabled' do
      before do
        stub_feature_flags(variable_inside_variable: false)
      end

      context 'table tests' do
        using RSpec::Parameterized::TableSyntax

        where do
          {
            "empty array": {
              variables: []
            },
            "simple expansions": {
              variables: [
                { key: 'variable', value: 'value' },
                { key: 'variable2', value: 'result' },
                { key: 'variable3', value: 'key$variable$variable2' }
              ]
            },
            "complex expansion": {
              variables: [
                { key: 'variable', value: 'value' },
                { key: 'variable2', value: 'key${variable}' }
              ]
            },
            "complex expansions with missing variable for Windows": {
              variables: [
                { key: 'variable', value: 'value' },
                { key: 'variable3', value: 'key%variable%%variable2%' }
              ]
            },
            "out-of-order variable reference": {
              variables: [
                { key: 'variable2', value: 'key${variable}' },
                { key: 'variable', value: 'value' }
              ]
            },
            "array with cyclic dependency": {
              variables: [
                { key: 'variable', value: '$variable2' },
                { key: 'variable2', value: '$variable3' },
                { key: 'variable3', value: 'key$variable$variable2' }
              ]
            }
          }
        end

        with_them do
          let_it_be(:project) { create(:project) }
          subject { Gitlab::Ci::Variables::Collection::Sorted.new(variables, project) }

          it 'does not expand variables' do
            expect(subject.sort).to eq(variables)
          end
        end
      end
    end

    context 'when FF :variable_inside_variable is enabled' do
      before do
        stub_licensed_features(group_saml_group_sync: true)
        stub_feature_flags(saml_group_links: true)
        stub_feature_flags(variable_inside_variable: true)
      end

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
            "cyclic dependency causes original array to be returned": {
              variables: [
                { key: 'variable2', value: '$variable3' },
                { key: 'variable3', value: 'key$variable$variable2' },
                { key: 'variable', value: '$variable2' }
              ],
              result: %w[variable2 variable3 variable]
            }
          }
        end

        with_them do
          let_it_be(:project) { create(:project) }
          subject { Gitlab::Ci::Variables::Collection::Sorted.new(variables, project) }

          it 'sort returns correctly sorted variables' do
            expect(subject.sort.map { |var| var[:key] }).to eq(result)
          end
        end
      end
    end
  end
end
