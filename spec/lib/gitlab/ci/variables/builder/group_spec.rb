# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder::Group, feature_category: :ci_variables do
  let_it_be(:group) { create(:group) }

  let(:builder) { described_class.new(group) }

  describe '#secret_variables' do
    let(:environment) { '*' }
    let(:protected_ref) { false }

    let_it_be(:variable) do
      create(:ci_group_variable,
        value: 'secret',
        group: group)
    end

    let_it_be(:protected_variable) do
      create(:ci_group_variable, :protected,
        value: 'protected',
        group: group)
    end

    let(:variable_item) { item(variable) }
    let(:protected_variable_item) { item(protected_variable) }

    subject do
      builder.secret_variables(
        environment: environment,
        protected_ref: protected_ref)
    end

    context 'when the ref is not protected' do
      let(:protected_ref) { false }

      it 'contains only the CI variables' do
        is_expected.to contain_exactly(variable_item)
      end
    end

    context 'when the ref is protected' do
      let(:protected_ref) { true }

      it 'contains all the variables' do
        is_expected.to contain_exactly(variable_item, protected_variable_item)
      end
    end

    context 'when environment name is specified' do
      let(:environment) { 'review/name' }

      before do
        Ci::GroupVariable.update_all(environment_scope: environment_scope)
      end

      context 'when environment scope is exactly matched' do
        let(:environment_scope) { 'review/name' }

        it { is_expected.to contain_exactly(variable_item) }
      end

      context 'when environment scope is matched by wildcard' do
        let(:environment_scope) { 'review/*' }

        it { is_expected.to contain_exactly(variable_item) }
      end

      context 'when environment scope does not match' do
        let(:environment_scope) { 'review/*/special' }

        it { is_expected.not_to contain_exactly(variable_item) }
      end

      context 'when environment scope has _' do
        let(:environment_scope) { '*_*' }

        it 'does not treat it as wildcard' do
          is_expected.not_to contain_exactly(variable_item)
        end
      end

      context 'when environment name contains underscore' do
        let(:environment) { 'foo_bar/test' }
        let(:environment_scope) { 'foo_bar/*' }

        it 'matches literally for _' do
          is_expected.to contain_exactly(variable_item)
        end
      end

      # The environment name and scope cannot have % at the moment,
      # but we're considering relaxing it and we should also make sure
      # it doesn't break in case some data sneaked in somehow as we're
      # not checking this integrity in database level.
      context 'when environment scope has %' do
        let(:environment_scope) { '*%*' }

        it 'does not treat it as wildcard' do
          is_expected.not_to contain_exactly(variable_item)
        end
      end

      context 'when environment name contains a percent' do
        let(:environment) { 'foo%bar/test' }
        let(:environment_scope) { 'foo%bar/*' }

        it 'matches literally for _' do
          is_expected.to contain_exactly(variable_item)
        end
      end
    end

    context 'when variables with the same name have different environment scopes' do
      let(:environment) { 'review/name' }

      let_it_be(:partially_matched_variable) do
        create(:ci_group_variable,
          key: variable.key,
          value: 'partial',
          environment_scope: 'review/*',
          group: group)
      end

      let_it_be(:perfectly_matched_variable) do
        create(:ci_group_variable,
          key: variable.key,
          value: 'prefect',
          environment_scope: 'review/name',
          group: group)
      end

      it 'orders the variables from least to most matched' do
        variables_collection = Gitlab::Ci::Variables::Collection.new(
          [
            variable,
            partially_matched_variable,
            perfectly_matched_variable
          ]).to_runner_variables

        expect(subject.to_runner_variables).to eq(variables_collection)
      end
    end

    context 'when group has children' do
      let(:protected_ref) { true }

      let_it_be(:group_child_1) { create(:group, parent: group) }
      let_it_be(:group_child_2) { create(:group, parent: group_child_1) }

      let_it_be_with_reload(:group_child_3) do
        create(:group, parent: group_child_2)
      end

      let_it_be(:variable_child_1) do
        create(:ci_group_variable, group: group_child_1)
      end

      let_it_be(:variable_child_2) do
        create(:ci_group_variable, group: group_child_2)
      end

      let_it_be(:variable_child_3) do
        create(:ci_group_variable, group: group_child_3)
      end

      context 'traversal queries' do
        shared_examples 'correct ancestor order' do
          let(:builder) { described_class.new(group_child_3) }

          it 'returns all variables belonging to the group and parent groups' do
            expected_array1 = Gitlab::Ci::Variables::Collection.new(
              [protected_variable_item, variable_item])
            .to_runner_variables

            expected_array2 = Gitlab::Ci::Variables::Collection.new(
              [variable_child_1, variable_child_2, variable_child_3]
            ).to_runner_variables

            got_array = subject.to_runner_variables

            expect(got_array.shift(2)).to contain_exactly(*expected_array1)
            expect(got_array).to eq(expected_array2)
          end
        end

        include_examples 'correct ancestor order'
      end
    end
  end

  def item(variable)
    Gitlab::Ci::Variables::Collection::Item.fabricate(variable)
  end
end
