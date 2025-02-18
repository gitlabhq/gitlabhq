# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::HidableVariable, feature_category: :ci_variables do
  using RSpec::Parameterized::TableSyntax
  shared_examples 'HiddenVariableValidations' do |variable_class, association|
    let(:variable_key) { 'TESTKEY1' }
    let(:variable_value) { 'TESTVAL1' }

    let(:create_variable) do
      variable_class.new(association => send(association),
        masked: pending_masked,
        hidden: pending_hidden,
        key: variable_key, value: variable_value).save!
    end

    describe '#validate_masked_and_hidden_on_create' do
      subject(:validate_create) { create_variable }

      context 'when masked and hidden attribute are allowed' do
        where(:pending_masked, :pending_hidden) do
          true | true
          false | false
          true | false
        end

        with_them do
          it 'passes the validation' do
            expect do
              validate_create
            end.not_to raise_error
          end
        end
      end

      context 'when masked and hidden attribute are not allowed' do
        where(:pending_masked, :pending_hidden) do
          false | true
        end

        with_them do
          it 'raises an error' do
            expect do
              validate_create
            end.to raise_error(ActiveRecord::RecordInvalid,
              'Validation failed: Masked should be true when variable is hidden')
          end
        end
      end
    end

    describe '#validate_masked_and_hidden_on_update' do
      subject(:validate_update) do
        test_variable = variable_class.create!(association => send(association),
          masked: stored_masked,
          hidden: stored_hidden,
          key: variable_key, value: variable_value
        )
        test_variable.update!(masked: pending_masked, hidden: pending_hidden)
      end

      context 'when update is allowed' do
        where(:stored_masked, :stored_hidden, :pending_masked,
          :pending_hidden) do
          true | false | true | false
          true | false | false | false
          true | true | true | true
          false | false | true | false
        end

        with_them do
          it 'passed the validation' do
            expect do
              validate_update
            end.not_to raise_error
          end
        end
      end

      context 'when update is not allowed' do
        where(:stored_masked, :stored_hidden, :pending_masked,
          :pending_hidden) do
          true | true | true | false
          true | true | false | false
          true | true | false | true
          false | false | true | true
        end

        with_them do
          it 'does not pass the validation' do
            expected_error_message =
              if stored_hidden == pending_hidden && stored_masked != pending_masked
                'The visibility setting cannot be changed for masked and hidden variables.'
              else
                'Only new variables can be set as masked and hidden.'
              end

            expect do
              validate_update
            end.to raise_error(ActiveRecord::RecordInvalid,
              "Validation failed: #{expected_error_message}")
          end
        end
      end
    end
  end

  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  context 'with Ci::Variable' do
    it_behaves_like 'HiddenVariableValidations', Ci::Variable, :project
  end

  context 'with Ci::GroupVariable' do
    it_behaves_like 'HiddenVariableValidations', Ci::GroupVariable, :group
  end
end
